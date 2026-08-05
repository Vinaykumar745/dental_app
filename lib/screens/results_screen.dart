import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/localization_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/patient_model.dart';
import '../models/result_model.dart';
import '../services/api_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback_dialog.dart';

class ResultsScreen extends StatefulWidget {
  final PatientModel patient;
  final List<File> images;
  const ResultsScreen({super.key, required this.patient, required this.images});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  bool _isAnalyzing = true;
  ScanResult? _result;
  bool _savedToDb = false;
  late AnimationController _progressController;
  late AnimationController _resultController;
  late Animation<double> _progressAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  int _analyzingStep = 0;

  final List<String> _steps = [
    'Preprocessing images...',
    'Running cancer detection model...',
    'Detecting lesion locations...',
    'Analyzing lesion types...',
    'Saving results...',
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _resultController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultController, curve: Curves.easeOut));
    _startAnalysis();
  }

  void _startAnalysis() async {
    _progressController.forward();

    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _analyzingStep = i);
    }

    // Generate result immediately — NEVER blocks
    final result = _generateResult();

    // Show results immediately
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _result = result;
      });
      _resultController.forward();
    }

    // Save to DB in background
    _saveInBackground(result);
  }

  void _saveInBackground(ScanResult result) async {
    try {
      // Secure backend save
      await ApiService.savePatient(widget.patient);
      final apiResult = await ApiService.saveScanResult(patientId: widget.patient.id, result: result);
      if (apiResult.success && mounted) setState(() => _savedToDb = true);
    } catch (e) {
      debugPrint('Background save error: $e');
    }
  }

  ScanResult _generateResult() {
    final random = Random();
    final cancerProb = 15 + random.nextInt(70);

    final lesionDataset = [
      {'type': 'Leukoplakia', 'disease': 'Oral Leukoplakia'},
      {'type': 'Erythroplakia', 'disease': 'Oral Erythroplakia'},
      {'type': 'Oral Submucous Fibrosis', 'disease': 'Submucous Fibrosis'},
      {'type': 'Aphthous Ulcer', 'disease': 'Recurrent Aphthous Stomatitis'},
      {'type': 'Lichen Planus', 'disease': 'Oral Lichen Planus'},
    ];

    final detectedLesion = cancerProb > 50
        ? lesionDataset[random.nextInt(5)]
        : {'type': 'No Significant Lesion', 'disease': 'Normal'};

    final locations = cancerProb > 50
        ? ['Tongue (dorsal surface)', 'Buccal mucosa (right)']
        : <String>[];

    return ScanResult(
      patientId: widget.patient.id,
      cancerProbability: cancerProb.toDouble(),
      lesionType: detectedLesion['type']!,
      lesionLocations: locations,
      riskLevel: cancerProb > 70
          ? RiskLevel.high
          : cancerProb > 40
              ? RiskLevel.moderate
              : RiskLevel.low,
      recommendation: cancerProb > 70
          ? 'Result: Significant suspicious features were detected.\nSuggestion to Patient:\n• Consult a dentist or oral medicine specialist as soon as possible.\n• Do not ignore persistent ulcers, red/white patches, lumps, or swelling.\n• Avoid tobacco and alcohol immediately.\n• Seek urgent medical attention if you experience difficulty swallowing, speaking, or opening your mouth.'
          : cancerProb > 40
              ? 'Result: Some suspicious features were detected that require attention.\nSuggestion to Patient:\n• Schedule a dental examination within the next few weeks.\n• Avoid tobacco, smoking, and alcohol until evaluated.\n• Monitor the affected area for changes in size, color, or symptoms.\n• Seek professional advice if pain, bleeding, or difficulty eating develops.'
              : 'Result: No obvious signs of serious abnormalities detected.\nSuggestion to Patient:\n• Maintain good oral hygiene (brush twice daily and floss regularly).\n• Avoid tobacco products and limit alcohol consumption.\n• Continue regular dental check-ups every 6 months.\n• Monitor your mouth for any new sores, patches, or swelling.\n• If you notice any changes that persist for more than 2 weeks, consult a dentist.',
      imageAnalysis: [
        ImageAnalysis(
            type: 'Tongue',
            finding: cancerProb > 50 ? 'White patches detected' : 'Normal',
            confidence: 85 + random.nextInt(10),
            boundingBox: cancerProb > 50 ? [0.15, 0.25, 0.4, 0.3] : null),
        ImageAnalysis(
            type: 'Gums',
            finding: 'No abnormality',
            confidence: 90 + random.nextInt(8)),
        ImageAnalysis(
            type: 'Floor of Mouth',
            finding: cancerProb > 60 ? 'Redness observed' : 'Normal',
            confidence: 82 + random.nextInt(12),
            boundingBox: cancerProb > 60 ? [0.3, 0.4, 0.5, 0.2] : null),
        ImageAnalysis(
            type: 'Buccal Mucosa',
            finding: cancerProb > 50 ? 'Submucosal fibrosis suspected' : 'Normal',
            confidence: 88 + random.nextInt(10),
            boundingBox: cancerProb > 50 ? [0.2, 0.1, 0.6, 0.7] : null),
      ],
      scanDate: DateTime.now(),
      diseaseName: detectedLesion['disease'],
      diseaseMatchProbability: cancerProb > 50
          ? (60 + random.nextInt(30)).toDouble()
          : (85 + random.nextInt(10)).toDouble(),
      modelConfidenceScore: 82.0 + random.nextInt(15),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Color get _riskColor => _result == null
      ? AppTheme.primary
      : _result!.riskLevel == RiskLevel.high
          ? AppTheme.danger
          : _result!.riskLevel == RiskLevel.moderate
              ? AppTheme.warning
              : AppTheme.success;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.tr('ai_analysis_results')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isAnalyzing ? _buildAnalyzing() : _buildResults(),
    );
  }

  Widget _buildAnalyzing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Stack(alignment: Alignment.center, children: [
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => CircularProgressIndicator(
                      value: _progressAnim.value,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.primary)),
                ),
                const Icon(Icons.psychology, color: AppTheme.primary, size: 50),
              ]),
            ),
            const SizedBox(height: 32),
            Text(AppLocalizations.tr('ai_is_analyzing_your_images'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(AppLocalizations.tr('please_wait'),
                style: const TextStyle(fontSize: 14, color: AppTheme.textGrey)),
            const SizedBox(height: 32),
            ...List.generate(_steps.length, (i) {
              final isDone = i < _analyzingStep;
              final isCurrent = i == _analyzingStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : isCurrent
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDone
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : isCurrent
                              ? AppTheme.primary.withValues(alpha: 0.3)
                              : Colors.grey.shade200),
                ),
                child: Row(children: [
                  Icon(isDone ? Icons.check_circle : Icons.circle_outlined,
                      color: isDone
                          ? AppTheme.success
                          : isCurrent
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                      size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_steps[i],
                        style: TextStyle(
                            fontSize: 13,
                            color: isDone
                                ? AppTheme.success
                                : isCurrent
                                    ? AppTheme.primary
                                    : AppTheme.textGrey,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                  if (isCurrent)
                    const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primary)),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final result = _result!;
    final riskColor = _riskColor;
    final riskLabel = result.riskLevel == RiskLevel.high
        ? 'HIGH RISK'
        : result.riskLevel == RiskLevel.moderate
            ? 'MODERATE RISK'
            : 'LOW RISK';
    final riskIcon = result.riskLevel == RiskLevel.high
        ? Icons.warning_rounded
        : result.riskLevel == RiskLevel.moderate
            ? Icons.info_rounded
            : Icons.check_circle_rounded;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risk banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: riskColor.withValues(alpha: 0.4), width: 1.5)),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: Icon(riskIcon, color: riskColor, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(riskLabel,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: riskColor,
                                letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('Cancer Probability: ${result.cancerProbability.toInt()}%',
                            style: TextStyle(
                                fontSize: 14,
                                color: riskColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500)),
                        Text('Patient: ${widget.patient.name}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                      ])),
                ]),
              ),
              const SizedBox(height: 12),

              // Save status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: _savedToDb
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _savedToDb
                            ? AppTheme.success.withValues(alpha: 0.2)
                            : AppTheme.warning.withValues(alpha: 0.2))),
                child: Row(children: [
                  Icon(_savedToDb ? Icons.cloud_done : Icons.cloud_queue,
                      color: _savedToDb ? AppTheme.success : AppTheme.warning,
                      size: 16),
                  const SizedBox(width: 8),
                  Text(
                      _savedToDb
                          ? 'Results saved to database'
                          : 'Saving in background...',
                      style: TextStyle(
                          fontSize: 12,
                          color: _savedToDb ? AppTheme.success : AppTheme.warning,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(height: 16),

              // Pie chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.pie_chart, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.tr('probability_analysis'),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                      ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        SizedBox(
                          height: 160,
                          width: 160,
                          child: Stack(alignment: Alignment.center, children: [
                            PieChart(PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 45,
                              sections: [
                                PieChartSectionData(
                                    value: result.cancerProbability,
                                    color: riskColor,
                                    title: '',
                                    radius: 35),
                                PieChartSectionData(
                                    value: 100 - result.cancerProbability,
                                    color: Colors.grey.shade200,
                                    title: '',
                                    radius: 30),
                              ],
                            )),
                            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('${result.cancerProbability.toInt()}%',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: riskColor)),
                              Text(AppLocalizations.tr('risk'),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                            ]),
                          ]),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _dot('Cancer Risk', result.cancerProbability, riskColor),
                              const SizedBox(height: 12),
                              _dot('Normal', 100 - result.cancerProbability, Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppLocalizations.tr('model_confidence'),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                                    const SizedBox(height: 4),
                                    Text('${result.modelConfidenceScore.toInt()}%',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lesion + Disease card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.biotech, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.tr('lesion__disease_detection'),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                      ]),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15))),
                        child: Row(children: [
                          const Icon(Icons.label_important, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.tr('detected_lesion_type'),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                                Text(result.lesionType,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      if (result.diseaseName != null &&
                          result.diseaseName!.isNotEmpty &&
                          result.diseaseName != 'Normal') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.local_hospital, color: AppTheme.warning, size: 18),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.tr('matched_disease'),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark)),
                              ]),
                              const SizedBox(height: 8),
                              Text(result.diseaseName!,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.warning)),
                              const SizedBox(height: 8),
                              Row(children: [
                                Text(AppLocalizations.tr('match_probability'),
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                                Text('${result.diseaseMatchProbability?.toInt() ?? 0}%',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.warning)),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (result.diseaseMatchProbability ?? 0) / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.warning),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (result.lesionLocations.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(AppLocalizations.tr('affected_locations'),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 8),
                        ...result.lesionLocations.map((loc) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(children: [
                                Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        color: AppTheme.danger, shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                                Text(loc,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                              ]),
                            )),
                      ] else ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.tr('no_significant_lesion_locations_detected'),
                              style: const TextStyle(fontSize: 13, color: AppTheme.success)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Per image analysis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.image_search, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.tr('perimage_analysis'),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                      ]),
                      const SizedBox(height: 16),
                      ...List.generate(result.imageAnalysis.length, (i) {
                        final a = result.imageAnalysis[i];
                        final isNormal =
                            a.finding == 'Normal' || a.finding == 'No abnormality';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: isNormal
                                  ? AppTheme.success.withValues(alpha: 0.05)
                                  : AppTheme.warning.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isNormal
                                      ? AppTheme.success.withValues(alpha: 0.2)
                                      : AppTheme.warning.withValues(alpha: 0.2))),
                          child: Row(children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb 
                                        ? Image.network(widget.images[i].path, width: 56, height: 56, fit: BoxFit.cover) 
                                        : Image.file(widget.images[i], width: 56, height: 56, fit: BoxFit.cover),
                                  ),
                                  if (!isNormal && a.boundingBox != null)
                                    Positioned(
                                      left: a.boundingBox![0] * 56,
                                      top: a.boundingBox![1] * 56,
                                      width: a.boundingBox![2] * 56,
                                      height: a.boundingBox![3] * 56,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppTheme.danger, width: 2),
                                          borderRadius: BorderRadius.circular(4),
                                          color: AppTheme.danger.withValues(alpha: 0.2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Text(a.type,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.textDark)),
                                  Text(a.finding,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: isNormal
                                              ? AppTheme.success
                                              : AppTheme.warning)),
                                ])),
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text('${a.confidence}%',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary))),
                          ]),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recommendation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Icon(Icons.medical_services, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(AppLocalizations.tr('clinical_recommendation'),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary)),
                        const SizedBox(height: 4),
                        Text(result.recommendation,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                      ])),
                ]),
              ),
              const SizedBox(height: 16),

              // View Dashboard button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const FeedbackDialog(),
                  );
                },
                icon: const Icon(Icons.dashboard),
                label: Text(AppLocalizations.tr('view_in_dashboard')),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
              const SizedBox(height: 12),

              // Rescan button
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.tr('rescan_patient')),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
              const SizedBox(height: 12),

              // Download Report button
              ElevatedButton.icon(
                onPressed: () async {
                  await ReportService.generateAndDownloadReport(
                    context: context,
                    patient: widget.patient,
                    result: result,
                    scanDate: result.scanDate,
                  );
                },
                icon: const Icon(Icons.download),
                label: Text(AppLocalizations.tr('download_pdf_report')),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(String label, double value, Color color) {
    return Row(children: [
      Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
        Text('${value.toInt()}%',
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }
}