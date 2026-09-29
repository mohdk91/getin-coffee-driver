import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/documents/data/driver_documents_repository.dart';
import 'package:getin_driver/features/documents/domain/driver_document_models.dart';

void main() {
  final now = DateTime(2026, 9, 26, 12);

  test('Task 34 demo repository exposes all required document types', () async {
    final repository = DemoDriverDocumentsRepository(now: now);

    final result = await repository.loadDocuments();

    expect(result.isSuccess, isTrue);
    expect(repository.source, DriverDocumentDataSource.demo);
    expect(result.documents, hasLength(4));
    expect(
      result.documents!.map((item) => item.type),
      containsAll(const [
        DriverDocumentType.identity,
        DriverDocumentType.driverLicense,
        DriverDocumentType.vehicleRegistration,
        DriverDocumentType.insurance,
      ]),
    );
  });

  test('Task 34 exposes expiry warning from expiry date and policy window',
      () async {
    final repository = DemoDriverDocumentsRepository(now: now);
    final result = await repository.loadDocuments();
    final license = result.documents!.firstWhere(
      (item) => item.type == DriverDocumentType.driverLicense,
    );

    expect(license.daysUntilExpiry(now), 18);
    expect(license.hasExpiryWarningAt(now), isTrue);
    expect(
      license.expiryStateAt(now),
      DriverDocumentExpiryState.expiringSoon,
    );
  });

  test('Task 34 replacement submission moves document into review', () async {
    final repository = DemoDriverDocumentsRepository(now: now);

    final result = await repository.uploadReplacement(
      const DriverDocumentReplacementRequest(
        documentId: 'doc-license',
        fileName: 'renewed-license.pdf',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(
      result.document!.approvalState,
      DriverDocumentApprovalState.pendingReview,
    );
    expect(result.document!.replacementFileName, 'renewed-license.pdf');
  });

  test('Task 34 rejects unsupported replacement file extensions', () async {
    final repository = DemoDriverDocumentsRepository(now: now);

    final result = await repository.uploadReplacement(
      const DriverDocumentReplacementRequest(
        documentId: 'doc-license',
        fileName: 'renewed-license.exe',
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('PDF'));
  });

  test('Task 34 unavailable repository never invents production documents',
      () async {
    const repository = UnavailableDriverDocumentsRepository();

    final result = await repository.loadDocuments();

    expect(repository.source, DriverDocumentDataSource.api);
    expect(result.isSuccess, isFalse);
    expect(result.documents, isNull);
    expect(result.errorMessage, contains('Laravel API'));
  });
}
