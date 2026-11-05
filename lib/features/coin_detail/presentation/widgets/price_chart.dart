import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/coin_detail.dart';

/// Touch/drag to inspect any point; tooltip shows price and time.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.points, required this.days});

  final List<ChartPoint> points;
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary; // gold line, like the reference design

    final prices = points.map((p) => p.price);
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) == 0 ? maxY * 0.01 : (maxY - minY) * 0.08;

    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].price),
    ];

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: theme.colorScheme.outline.withValues(alpha: 0.18), strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (touched) => [
              for (final t in touched)
                LineTooltipItem(
                  '${Fmt.price(points[t.spotIndex].price)}\n',
                  TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: Fmt.chartDate(points[t.spotIndex].timestamp, days),
                      style: TextStyle(
                        color: theme.colorScheme.onInverseSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.15,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}
