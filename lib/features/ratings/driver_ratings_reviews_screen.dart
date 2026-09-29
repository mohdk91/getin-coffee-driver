import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import 'data/driver_ratings_repository.dart';
import 'domain/driver_rating_models.dart';
import '../support/driver_support_chat_screen.dart';

class DriverRatingsReviewsScreen extends StatefulWidget {
  final AppConfig config;
  final DriverRatingsRepository? repository;
  final ValueChanged<DriverCustomerReview>? onReportReview;

  const DriverRatingsReviewsScreen({
    super.key,
    required this.config,
    this.repository,
    this.onReportReview,
  });

  @override
  State<DriverRatingsReviewsScreen> createState() =>
      _DriverRatingsReviewsScreenState();
}

class _DriverRatingsReviewsScreenState
    extends State<DriverRatingsReviewsScreen> {
  late final DriverRatingsRepository _repository =
      widget.repository ?? DriverRatingsRepositoryFactory.create(widget.config);

  DriverRatingsSnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _repository.loadRatings();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _snapshot = result.snapshot;
      _errorMessage = result.errorMessage;
    });
  }

  void _reportReview(DriverCustomerReview review) {
    final callback = widget.onReportReview;
    if (callback != null) {
      callback(review);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverSupportChatScreen(
          config: widget.config,
          contextOrderNumber: review.orderNumber,
          initialDraft:
              'I want to report/dispute the customer review for order ${review.orderNumber}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const Scaffold(
        body: SafeArea(
          child: AppLoadingState(label: 'Loading ratings and reviews…'),
        ),
      );
    }

    if (_snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ratings & Reviews')),
        body: SafeArea(
          child: AppStateView.error(
            title: 'Ratings unavailable',
            message: _errorMessage ?? 'Could not load ratings and reviews.',
            onRetry: _load,
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ratings & Reviews')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 28),
          children: [
            const Text(
              'Your delivery rating',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Customer feedback is read-only. Ratings cannot be edited by the driver.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (_repository.source == DriverRatingsDataSource.demo) ...[
              const SizedBox(height: 10),
              const Text(
                'DEMO RATINGS • Not connected to Laravel customer reviews',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _RatingSummaryCard(snapshot: snapshot),
            const SizedBox(height: 14),
            _RatingDistributionCard(snapshot: snapshot),
            const SizedBox(height: 18),
            const Text(
              'What customers mention',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _TagSummaryWrap(items: snapshot.tagSummary),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent reviews',
                    style: TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${snapshot.ratingCount} ratings',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (snapshot.recentReviews.isEmpty)
              const _EmptyReviewsCard()
            else
              ...snapshot.recentReviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewCard(
                    review: review,
                    onReport: () => _reportReview(review),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            const _ReviewPolicyCard(),
          ],
        ),
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  final DriverRatingsSnapshot snapshot;

  const _RatingSummaryCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                snapshot.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 42,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: _StarRow(rating: 5, color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${snapshot.ratingCount} ratings from ${snapshot.deliveryCount} deliveries',
            style: const TextStyle(
              color: AppColors.beige,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingDistributionCard extends StatelessWidget {
  final DriverRatingsSnapshot snapshot;

  const _RatingDistributionCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating distribution',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          for (var stars = 5; stars >= 1; stars--) ...[
            _DistributionRow(
              bucket: snapshot.bucketFor(stars),
              total: snapshot.ratingCount,
            ),
            if (stars > 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final DriverRatingBucket bucket;
  final int total;

  const _DistributionRow({required this.bucket, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : bucket.count / total;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '${bucket.stars}',
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Icon(Icons.star_rounded, color: AppColors.gold, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.cream,
              color: AppColors.green,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            '${bucket.count}',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagSummaryWrap extends StatelessWidget {
  final List<DriverReviewTagSummary> items;

  const _TagSummaryWrap({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: item.tag == DriverReviewTag.late
                    ? AppColors.warning.withOpacity(.10)
                    : AppColors.cream,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${item.tag.label} · ${item.count}',
                style: TextStyle(
                  color: item.tag == DriverReviewTag.late
                      ? AppColors.warning
                      : AppColors.greenDark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final DriverCustomerReview review;
  final VoidCallback onReport;

  const _ReviewCard({required this.review, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.orderNumber,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StarRow(rating: review.rating, color: AppColors.gold),
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        tag.label,
                        style: const TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              review.comment!,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.flag_outlined, size: 17),
              label: const Text('Report / dispute via Support'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  final Color color;

  const _StarRow({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}

class _EmptyReviewsCard extends StatelessWidget {
  const _EmptyReviewsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'No customer reviews are available yet.',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReviewPolicyCard extends StatelessWidget {
  const _ReviewPolicyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Customer reviews are read-only. Drivers cannot edit or delete feedback. If a review needs investigation, report or dispute it through Getin Support.',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
