import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales & Inventory Analytics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MetricCard(title: 'Total Revenue', value: '\$12,450', change: '+12%'),
            _MetricCard(title: 'Orders', value: '342', change: '+4%'),
            _MetricCard(title: 'Low Stock Items', value: '18', change: '-3%'),
            const SizedBox(height: 12),
            _ChartPlaceholder(title: 'Sales Trend'),
            const SizedBox(height: 12),
            _ChartPlaceholder(title: 'Inventory Turnover'),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;

  const _MetricCard({required this.title, required this.value, required this.change});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppColors.textMuted)),
        subtitle: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        trailing: Text(change, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final String title;

  const _ChartPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Icon(Icons.show_chart, size: 48, color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ],
      ),
    );
  }
}
