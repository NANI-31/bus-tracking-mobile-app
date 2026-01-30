import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AppPieChart extends StatelessWidget {
  final Map<String, double> data;
  final List<Color> colors;
  final String title;
  final double height;

  const AppPieChart({
    super.key,
    required this.data,
    required this.colors,
    required this.title,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data available for $title',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: height,
          child: PieChart(
            PieChartData(
              sections: _buildSections(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    int index = 0;
    return data.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.value.toInt()}',
        radius: 25,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    int index = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: data.entries.map((entry) {
        final color = colors[index % colors.length];
        index++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(entry.key, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}

class AppLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final String title;
  final double height;
  final Color lineColor;

  const AppLineChart({
    super.key,
    required this.spots,
    required this.title,
    this.height = 200,
    this.lineColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No trend data available')),
      );
    }

    return Column(
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
