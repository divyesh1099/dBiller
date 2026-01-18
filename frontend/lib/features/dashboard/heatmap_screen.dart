import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';

class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Dashboard Heatmap'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Engagement Heatmap',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Center(
                child: Icon(Icons.grid_view, size: 60, color: Colors.white.withOpacity(0.3)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Top Hotspots',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              4,
              (index) => ListTile(
                leading: const Icon(Icons.bolt, color: AppColors.primary),
                title: Text('Hotspot ${index + 1}'),
                subtitle: const Text('High activity area'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
