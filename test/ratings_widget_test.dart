import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/ratings/domain/driver_rating_models.dart';
import 'package:getin_driver/features/ratings/driver_ratings_reviews_screen.dart';

const config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

Future<void> _scrollTo(WidgetTester tester, String text) async {
  final scrollable = find.byType(ListView);
  for (var attempt = 0; attempt < 12; attempt++) {
    final target = find.text(text);
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(scrollable, const Offset(0, -280));
    await tester.pumpAndSettle();
  }
  expect(find.text(text), findsWidgets);
}

void main() {
  testWidgets('Task 28 renders rating summary distribution and tags', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverRatingsReviewsScreen(config: config),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your delivery rating'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('126 ratings from 164 deliveries'), findsOneWidget);
    expect(find.text('Rating distribution'), findsOneWidget);

    await _scrollTo(tester, 'Fast delivery · 98');
    expect(find.text('Fast delivery · 98'), findsOneWidget);
    expect(find.text('Friendly · 87'), findsOneWidget);
    expect(find.text('Careful handling · 79'), findsOneWidget);
    expect(find.text('Easy communication · 68'), findsOneWidget);
    expect(find.text('Late · 2'), findsOneWidget);
  });

  testWidgets('Task 28 recent review can only be disputed through support', (
    tester,
  ) async {
    DriverCustomerReview? reported;

    await tester.pumpWidget(
      MaterialApp(
        home: DriverRatingsReviewsScreen(
          config: config,
          onReportReview: (review) => reported = review,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, 'GD-2481');
    expect(find.text('GD-2481'), findsOneWidget);
    expect(
        find.text('Quick and friendly delivery. Thank you.'), findsOneWidget);

    await _scrollTo(tester, 'Report / dispute via Support');
    final reportLabel = find.text('Report / dispute via Support').first;
    expect(reportLabel, findsOneWidget);
    await tester.tap(reportLabel);
    await tester.pumpAndSettle();

    expect(reported, isNotNull);
    expect(reported!.orderNumber, 'GD-2481');
    expect(
        find.text('Quick and friendly delivery. Thank you.'), findsOneWidget);
    expect(find.textContaining('Edit review'), findsNothing);
    expect(find.textContaining('Delete review'), findsNothing);
  });
}
