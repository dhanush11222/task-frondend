import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Tiny non-interactive trend line for list rows.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.data, required this.color, this.width = 60, this.height = 32});

  final List<double> data;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(width: width, height: height);
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) == 0 ? (maxY.abs() * 0.01 + 1e-9) : (maxY - minY) * 0.1;
    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])],
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 1.8,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
