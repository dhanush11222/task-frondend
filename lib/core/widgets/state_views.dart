import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../error/failure.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failure.isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 56,
              color: scheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              failure.isNetwork ? 'Connection problem' : 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(failure.message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder rows shown while the first page loads.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget box(double w, double h, {double r = 6}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r)),
        );
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainerHigh,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              box(40, 40, r: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [box(110, 14), const SizedBox(height: 8), box(170, 11)],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [box(70, 14), const SizedBox(height: 8), box(48, 11)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SourceBanner extends StatelessWidget {
  const SourceBanner({super.key, required this.source});

  final String? source;

  @override
  Widget build(BuildContext context) {
    if (source != 'mock') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Text(
        'Showing sample data (live API unavailable)',
        style: Theme.of(context).textTheme.labelSmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
