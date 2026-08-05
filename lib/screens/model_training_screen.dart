import 'dart:math';
import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class ModelTrainingScreen extends StatefulWidget {
  const ModelTrainingScreen({super.key});

  @override
  State<ModelTrainingScreen> createState() => _ModelTrainingScreenState();
}

class _ModelTrainingScreenState extends State<ModelTrainingScreen> {
  final List<FlSpot> _accuracyData = [];
  final List<FlSpot> _lossData = [];
  bool _isTraining = false;
  int _epoch = 40;

  @override
  void initState() {
    super.initState();
    // Initial data for 40 epochs
    for (int i = 0; i <= 40; i++) {
      _accuracyData.add(FlSpot(i.toDouble(), 0.60 + (0.35 * (1 - exp(-i / 10)))));
      _lossData.add(FlSpot(i.toDouble(), 0.80 * exp(-i / 15) + 0.1));
    }
  }

  void _simulateFurtherTraining() async {
    if (_isTraining) return;
    setState(() => _isTraining = true);
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _epoch++;
        final currentAcc = _accuracyData.last.y;
        final newAcc = min(0.99, currentAcc + Random().nextDouble() * 0.005);
        _accuracyData.add(FlSpot(_epoch.toDouble(), newAcc));

        final currentLoss = _lossData.last.y;
        final newLoss = max(0.01, currentLoss - Random().nextDouble() * 0.01);
        _lossData.add(FlSpot(_epoch.toDouble(), newLoss));
      });
    }
    setState(() => _isTraining = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.tr('ai_model_training__validation')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF283048), Color(0xFF859398)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.tr('model_status'),
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isTraining ? AppTheme.warning : AppTheme.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_isTraining ? 'TRAINING...' : 'READY',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.tr('oral_pathology_v32'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('Epochs', '$_epoch/100'),
                      _stat('Accuracy', '${(_accuracyData.last.y * 100).toStringAsFixed(1)}%'),
                      _stat('Dataset', '45,210 Imgs'),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Train Button
            ElevatedButton.icon(
              onPressed: _isTraining ? null : _simulateFurtherTraining,
              icon: _isTraining
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.model_training),
              label: Text(_isTraining ? 'Training in progress...' : 'Continue Training (10 Epochs)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Accuracy Chart
            Text(AppLocalizations.tr('validation_accuracy'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _accuracyData,
                      isCurved: true,
                      color: AppTheme.success,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.success.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                  minY: 0.5,
                  maxY: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Loss Chart
            Text(AppLocalizations.tr('training_loss'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _lossData,
                      isCurved: true,
                      color: AppTheme.danger,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.danger.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                  minY: 0.0,
                  maxY: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
