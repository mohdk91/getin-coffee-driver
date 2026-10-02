import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_document_models.dart';

abstract interface class DriverDocumentsRepository {
  DriverDocumentDataSource get source;

  Future<DriverDocumentsLoadResult> loadDocuments();

  Future<DriverDocumentReplacementResult> uploadReplacement(
    DriverDocumentReplacementRequest request,
  );
}

class DriverDocumentsRepositoryFactory {
  DriverDocumentsRepositoryFactory._();

  static DriverDocumentsRepository create(AppConfig config,
      {DriverApiContext? context}) {
    if (config.isApiConfigured) {
      return ApiDriverDocumentsRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    return config.allowsDemo
        ? DemoDriverDocumentsRepository()
        : const UnavailableDriverDocumentsRepository();
  }
}

class ApiDriverDocumentsRepository implements DriverDocumentsRepository {
  final DriverApiContext context;
  const ApiDriverDocumentsRepository(this.context);
  @override
  DriverDocumentDataSource get source => DriverDocumentDataSource.api;
  @override
  Future<DriverDocumentsLoadResult> loadDocuments() async {
    try {
      final items = DriverApiContext.nestedItems(await context.apiClient
          .getJson('/v1/driver/documents', authenticated: true));
      return DriverDocumentsLoadResult.success(items
          .whereType<Map>()
          .map((item) => _map(Map<String, dynamic>.from(item)))
          .toList(growable: false));
    } on ApiException catch (e) {
      return DriverDocumentsLoadResult.failure(e.message);
    } on FormatException catch (e) {
      return DriverDocumentsLoadResult.failure(e.message);
    }
  }

  @override
  Future<DriverDocumentReplacementResult> uploadReplacement(
      DriverDocumentReplacementRequest request) async {
    final id = int.tryParse(request.documentId);
    final path = request.filePath;
    if (id == null || path == null || path.isEmpty) {
      return const DriverDocumentReplacementResult.failure(
        'Choose a local PDF or image file before uploading a production replacement.',
      );
    }
    try {
      final data = DriverApiContext.dataMap(await context.apiClient
          .postMultipartFile('/v1/driver/documents/$id/replace',
              filePath: path, authenticated: true));
      return DriverDocumentReplacementResult.success(_map(data));
    } on ApiException catch (e) {
      return DriverDocumentReplacementResult.failure(e.message);
    }
  }

  DriverDocumentSnapshot _map(Map<String, dynamic> data) {
    final rawType = data['document_type']?.toString().toLowerCase() ?? '';
    final type = rawType.contains('license')
        ? DriverDocumentType.driverLicense
        : rawType.contains('insurance')
            ? DriverDocumentType.insurance
            : rawType.contains('vehicle') || rawType.contains('registration')
                ? DriverDocumentType.vehicleRegistration
                : DriverDocumentType.identity;
    final status = switch (data['status']?.toString().toLowerCase()) {
      'approved' => DriverDocumentApprovalState.approved,
      'rejected' => DriverDocumentApprovalState.rejected,
      'expired' => DriverDocumentApprovalState.expired,
      'missing' => DriverDocumentApprovalState.missing,
      _ => DriverDocumentApprovalState.pendingReview
    };
    final reference = data['reference_number']?.toString().trim();
    return DriverDocumentSnapshot(
        id: data['id']?.toString() ?? '',
        type: type,
        referenceLabel: (reference == null || reference.isEmpty)
            ? (data['title']?.toString() ?? type.label)
            : reference,
        approvalState: status,
        expiryDate: DateTime.tryParse(data['expiry_date']?.toString() ?? ''),
        replacementAllowed: status != DriverDocumentApprovalState.pendingReview,
        replacementFileName: data['original_name']?.toString(),
        replacementSubmittedAt:
            DateTime.tryParse(data['uploaded_at']?.toString() ?? ''));
  }
}

class DemoDriverDocumentsRepository implements DriverDocumentsRepository {
  DemoDriverDocumentsRepository({DateTime? now})
      : _now = now ?? DateTime.now(),
        _documents = _buildDemoDocuments(now ?? DateTime.now());

  final DateTime _now;
  final List<DriverDocumentSnapshot> _documents;

  static List<DriverDocumentSnapshot> _buildDemoDocuments(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      DriverDocumentSnapshot(
        id: 'doc-id',
        type: DriverDocumentType.identity,
        referenceLabel: 'ID •••• 2194',
        approvalState: DriverDocumentApprovalState.approved,
        expiryDate: today.add(const Duration(days: 420)),
        replacementAllowed: true,
      ),
      DriverDocumentSnapshot(
        id: 'doc-license',
        type: DriverDocumentType.driverLicense,
        referenceLabel: 'License •••• 8841',
        approvalState: DriverDocumentApprovalState.approved,
        expiryDate: today.add(const Duration(days: 18)),
        replacementAllowed: true,
      ),
      DriverDocumentSnapshot(
        id: 'doc-vehicle',
        type: DriverDocumentType.vehicleRegistration,
        referenceLabel: 'Vehicle registration •••• 2417',
        approvalState: DriverDocumentApprovalState.approved,
        expiryDate: today.add(const Duration(days: 210)),
        replacementAllowed: true,
      ),
      DriverDocumentSnapshot(
        id: 'doc-insurance',
        type: DriverDocumentType.insurance,
        referenceLabel: 'Insurance policy •••• 7310',
        approvalState: DriverDocumentApprovalState.pendingReview,
        expiryDate: today.add(const Duration(days: 90)),
        replacementAllowed: true,
        replacementFileName: 'insurance-renewal.pdf',
        replacementSubmittedAt: today.subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  DriverDocumentDataSource get source => DriverDocumentDataSource.demo;

  @override
  Future<DriverDocumentsLoadResult> loadDocuments() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return DriverDocumentsLoadResult.success(
      List<DriverDocumentSnapshot>.unmodifiable(_documents),
    );
  }

  @override
  Future<DriverDocumentReplacementResult> uploadReplacement(
    DriverDocumentReplacementRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));

    final index =
        _documents.indexWhere((item) => item.id == request.documentId);
    if (index < 0) {
      return const DriverDocumentReplacementResult.failure(
        'Document record was not found.',
      );
    }

    final current = _documents[index];
    if (!current.replacementAllowed) {
      return const DriverDocumentReplacementResult.failure(
        'Replacement upload is not allowed for this document.',
      );
    }

    final fileName = request.fileName.trim();
    if (fileName.isEmpty || !_isAllowedFileName(fileName)) {
      return const DriverDocumentReplacementResult.failure(
        'Use a PDF, JPG, JPEG or PNG replacement file.',
      );
    }

    final updated = current.copyWith(
      approvalState: DriverDocumentApprovalState.pendingReview,
      replacementFileName: fileName,
      replacementSubmittedAt: _now,
    );
    _documents[index] = updated;
    return DriverDocumentReplacementResult.success(updated);
  }

  bool _isAllowedFileName(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }
}

class UnavailableDriverDocumentsRepository
    implements DriverDocumentsRepository {
  const UnavailableDriverDocumentsRepository();

  @override
  DriverDocumentDataSource get source => DriverDocumentDataSource.api;

  @override
  Future<DriverDocumentsLoadResult> loadDocuments() async {
    return const DriverDocumentsLoadResult.failure(
      'Driver documents are not connected to the Laravel API yet. Getin will not invent production approval or expiry data.',
    );
  }

  @override
  Future<DriverDocumentReplacementResult> uploadReplacement(
    DriverDocumentReplacementRequest request,
  ) async {
    return const DriverDocumentReplacementResult.failure(
      'Replacement uploads require the Laravel documents API.',
    );
  }
}
