import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data_model.dart';

/// Widget that displays sensor data as real-time charts with clean, modern design
class SensorChartsWidget extends StatelessWidget {
  final List<SensorDataModel> sensorDataHistory;
  final int maxDataPoints;

  const SensorChartsWidget({
    super.key,
    required this.sensorDataHistory,
    this.maxDataPoints = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (sensorDataHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'No Sensor Data Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Charts will appear here when data is received',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Take only the most recent data points
    final recentData = sensorDataHistory.length > maxDataPoints
        ? sensorDataHistory.sublist(sensorDataHistory.length - maxDataPoints)
        : sensorDataHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompactChart(
            context,
            'Temperature',
            Icons.thermostat,
            Colors.red,
            '°C',
            recentData,
            (d) => d.temperature,
            recentData.isEmpty ? 20.0 : recentData.map((d) => d.temperature).reduce((a, b) => a < b ? a : b) - 2,
            recentData.isEmpty ? 30.0 : recentData.map((d) => d.temperature).reduce((a, b) => a > b ? a : b) + 2,
          ),
          const SizedBox(height: 16),
          _buildCompactChart(
            context,
            'Humidity',
            Icons.water_drop,
            Colors.blue,
            '%',
            recentData,
            (d) => d.humidity,
            0,
            100,
          ),
          const SizedBox(height: 16),
          _buildCompactChart(
            context,
            'Motion',
            Icons.accessibility_new,
            Colors.purple,
            'm/s²',
            recentData,
            (d) => d.motion.magnitude,
            0,
            recentData.isEmpty ? 5.0 : (recentData.map((d) => d.motion.magnitude).reduce((a, b) => a > b ? a : b) * 1.3).clamp(0, 10),
          ),
          const SizedBox(height: 16),
          _buildCompactChart(
            context,
            'Sound Level',
            Icons.volume_up,
            Colors.green,
            '',
            recentData,
            (d) => d.sound.toDouble(),
            0,
            recentData.isEmpty ? 200.0 : (recentData.map((d) => d.sound.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2).clamp(0, 500),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChart(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String unit,
    List<SensorDataModel> data,
    double Function(SensorDataModel) getValue,
    double minY,
    double maxY,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    final currentValue = getValue(data.last);
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), getValue(e.value))).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title, and current value
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentValue.toStringAsFixed(unit == '%' ? 1 : unit == 'm/s²' ? 2 : 0)}$unit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Chart
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: (maxY - minY) / 4,
                        getTitlesWidget: (value, meta) {
                          if (value < minY || value > maxY) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toStringAsFixed(unit == '%' ? 0 : 1),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  minY: minY,
                  maxY: maxY,
                  minX: 0,
                  maxX: data.length > 1 ? (data.length - 1).toDouble() : 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                  clipData: const FlClipData.all(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
