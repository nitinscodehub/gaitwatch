import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/providers.dart';
import '../../widgets/reusable_widgets.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastResult = ref.watch(lastTestResultProvider);

    if (lastResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No test result available')),
      );
    }

    final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareResult(context, lastResult),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      RiskGauge(score: lastResult.riskScore, size: 220),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            lastResult.riskScore,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(lastResult.riskScore),
                              color: _getStatusColor(lastResult.riskScore),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lastResult.status.displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(lastResult.riskScore),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        dateFormat.format(lastResult.timestamp),
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
            const SizedBox(height: 24),
            _buildMetricsCard(context, lastResult)
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            _buildActionsCard(context, lastResult)
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            _buildRecommendationCard(context, lastResult.riskScore)
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard(BuildContext context, dynamic lastResult) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  Icons.straighten_rounded,
                  'Steps',
                  lastResult.stepCount?.toStringAsFixed(0) ?? '--',
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  Icons.swap_horiz_rounded,
                  'Avg Stride',
                  lastResult.averageStrideLength != null
                      ? '${lastResult.averageStrideLength!.toStringAsFixed(2)}m'
                      : '--',
                  AppColors.secondary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  Icons.speed_rounded,
                  'Velocity',
                  lastResult.gaitVelocity != null
                      ? '${lastResult.gaitVelocity!.toStringAsFixed(2)}m/s'
                      : '--',
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildActionsCard(BuildContext context, dynamic lastResult) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/graph'),
              icon: const Icon(Icons.show_chart_rounded),
              label: const Text('View Trend Graph'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateReport(context, lastResult),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, int riskScore) {
    String title;
    String description;
    IconData icon;
    Color color;

    if (riskScore < 25) {
      title = 'Great News!';
      description =
          'Your gait patterns appear healthy. Continue maintaining an active lifestyle with regular exercise and check-ups.';
      icon = Icons.celebration_rounded;
      color = AppColors.success;
    } else if (riskScore < 45) {
      title = 'Stay Proactive';
      description =
          'Your results show minor variations. Consider regular exercise and follow-up tests to monitor any changes.';
      icon = Icons.info_rounded;
      color = AppColors.secondary;
    } else if (riskScore < 65) {
      title = 'Consult a Specialist';
      description =
          'Your results indicate some gait abnormalities. We recommend consulting a healthcare professional for a thorough evaluation.';
      icon = Icons.warning_rounded;
      color = AppColors.warning;
    } else {
      title = 'Seek Medical Attention';
      description =
          'Your results show significant gait irregularities. Please consult a neurologist or movement disorder specialist as soon as possible.';
      icon = Icons.local_hospital_rounded;
      color = AppColors.danger;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int score) {
    if (score < 25) return AppColors.success;
    if (score < 45) return AppColors.secondary;
    if (score < 65) return AppColors.warning;
    return AppColors.danger;
  }

  IconData _getStatusIcon(int score) {
    if (score < 25) return Icons.check_circle_rounded;
    if (score < 45) return Icons.info_rounded;
    if (score < 65) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  Future<void> _generateReport(BuildContext context, dynamic lastResult) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating report...'),
          duration: Duration(seconds: 1),
        ),
      );

      final pdf = pw.Document();
      final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'GaitWatch Analysis Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Date: ${dateFormat.format(lastResult.timestamp)}'),
                pw.SizedBox(height: 10),
                pw.Text('Risk Score: ${lastResult.riskScore}/100'),
                pw.Text('Status: ${lastResult.status.displayName}'),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, text: 'Gait Metrics'),
                pw.Text(
                  'Steps: ${lastResult.stepCount?.toStringAsFixed(0) ?? "N/A"}',
                ),
                pw.Text(
                  'Average Stride: ${lastResult.averageStrideLength?.toStringAsFixed(2) ?? "N/A"}m',
                ),
                pw.Text(
                  'Gait Velocity: ${lastResult.gaitVelocity?.toStringAsFixed(2) ?? "N/A"} m/s',
                ),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, text: 'Disclaimer'),
                pw.Text(
                  'This report is for informational purposes only and should not be used as a substitute for professional medical advice.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/gait_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'GaitWatch Analysis Report');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate report'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _shareResult(BuildContext context, dynamic lastResult) async {
    final text =
        '''
GaitWatch Test Result
Risk Score: ${lastResult.riskScore}/100
Status: ${lastResult.status.displayName}
Date: ${DateFormat('MMM dd, yyyy').format(lastResult.timestamp)}

Generated by GaitWatch - Early Parkinson's Detection
''';

    await Share.share(text);
  }
}
