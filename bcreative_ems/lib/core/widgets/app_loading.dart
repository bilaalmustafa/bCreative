import 'package:bcreative_ems/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message ?? 'Loading content',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = (constraints.maxWidth - 40)
              .clamp(180.0, 680.0)
              .toDouble();
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: contentWidth * .42, height: 25),
                const SizedBox(height: 10),
                AppShimmer(width: contentWidth * .7, height: 13),
                const SizedBox(height: 26),
                LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final useTwoColumns = cardConstraints.maxWidth >= 620;
                    final cardWidth = useTwoColumns
                        ? (cardConstraints.maxWidth - 14) / 2
                        : cardConstraints.maxWidth;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: List.generate(
                        useTwoColumns ? 4 : 3,
                        (_) => AppShimmer(width: cardWidth, height: 116),
                      ),
                    );
                  },
                ),
                if (message != null) ...[
                  const SizedBox(height: 18),
                  Text(message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
