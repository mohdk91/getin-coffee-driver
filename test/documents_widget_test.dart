import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/documents/data/driver_documents_repository.dart';
import 'package:getin_driver/features/documents/domain/driver_document_models.dart';
import 'package:getin_driver/features/documents/driver_documents_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

class _FixedDocumentsRepository implements DriverDocumentsRepository {
  _FixedDocumentsRepository()
      : documents = [
          DriverDocumentSnapshot(
            id: 'fixed-id',
            type: DriverDocumentType.identity,
            referenceLabel: 'ID •••• 1001',
            approvalState: DriverDocumentApprovalState.approved,
            expiryDate: DateTime.now().add(const Duration(days: 400)),
            replacementAllowed: true,
          ),
          DriverDocumentSnapshot(
            id: 'fixed-license',
            type: DriverDocumentType.driverLicense,
            referenceLabel: 'License •••• 2002',
            approvalState: DriverDocumentApprovalState.approved,
            expiryDate: DateTime.now().add(const Duration(days: 12)),
            replacementAllowed: true,
          ),
          DriverDocumentSnapshot(
            id: 'fixed-vehicle',
            type: DriverDocumentType.vehicleRegistration,
            referenceLabel: 'Vehicle •••• 3003',
            approvalState: DriverDocumentApprovalState.approved,
            expiryDate: DateTime.now().add(const Duration(days: 180)),
            replacementAllowed: true,
          ),
          DriverDocumentSnapshot(
            id: 'fixed-insurance',
            type: DriverDocumentType.insurance,
            referenceLabel: 'Insurance •••• 4004',
            approvalState: DriverDocumentApprovalState.pendingReview,
            expiryDate: DateTime.now().add(const Duration(days: 90)),
            replacementAllowed: true,
          ),
        ];

  List<DriverDocumentSnapshot> documents;

  @override
  DriverDocumentDataSource get source => DriverDocumentDataSource.demo;

  @override
  Future<DriverDocumentsLoadResult> loadDocuments() async {
    return DriverDocumentsLoadResult.success(documents);
  }

  @override
  Future<DriverDocumentReplacementResult> uploadReplacement(
    DriverDocumentReplacementRequest request,
  ) async {
    final index = documents.indexWhere((item) => item.id == request.documentId);
    final updated = documents[index].copyWith(
      approvalState: DriverDocumentApprovalState.pendingReview,
      replacementFileName: request.fileName,
      replacementSubmittedAt: DateTime.now(),
    );
    documents = [
      for (var i = 0; i < documents.length; i++)
        if (i == index) updated else documents[i],
    ];
    return DriverDocumentReplacementResult.success(updated);
  }
}

class _FailedDocumentsRepository implements DriverDocumentsRepository {
  @override
  DriverDocumentDataSource get source => DriverDocumentDataSource.api;

  @override
  Future<DriverDocumentsLoadResult> loadDocuments() async {
    return const DriverDocumentsLoadResult.failure(
      'Documents API unavailable.',
    );
  }

  @override
  Future<DriverDocumentReplacementResult> uploadReplacement(
    DriverDocumentReplacementRequest request,
  ) async {
    return const DriverDocumentReplacementResult.failure(
      'Documents API unavailable.',
    );
  }
}

void main() {
  testWidgets('Task 34 renders required document records and expiry warning', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverDocumentsScreen(
          config: _config,
          repository: _FixedDocumentsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Driver license'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('document-card-fixed-insurance')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Vehicle documents'), findsOneWidget);
    expect(find.text('Insurance'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('document-expiry-warning-fixed-license')),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('document-expiry-warning-fixed-license')),
      findsOneWidget,
    );
  });

  testWidgets('Task 34 replacement upload submits document for review', (
    tester,
  ) async {
    final repository = _FixedDocumentsRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: DriverDocumentsScreen(
          config: _config,
          repository: repository,
          replacementFileSelector: () async => 'license-2027.pdf',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final licenseCard = find.byKey(const Key('document-card-fixed-license'));
    await tester.scrollUntilVisible(
      licenseCard,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final uploadLabel = find.descendant(
      of: licenseCard,
      matching: find.text('Upload replacement'),
    );
    expect(uploadLabel, findsOneWidget);
    await tester.tap(uploadLabel);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('document-replacement-fixed-license')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('document-replacement-fixed-license')),
      findsOneWidget,
    );
    expect(find.textContaining('license-2027.pdf'), findsOneWidget);
    expect(
      find.textContaining('Replacement selected and submitted for review'),
      findsOneWidget,
    );
  });

  testWidgets('Task 34 unavailable API state contains no demo records', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverDocumentsScreen(
          config: _config,
          repository: _FailedDocumentsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Documents unavailable'), findsOneWidget);
    expect(find.text('Documents API unavailable.'), findsOneWidget);
    expect(find.text('ID •••• 2194'), findsNothing);
  });
}
