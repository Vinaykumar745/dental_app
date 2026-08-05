import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/localization_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/patient_model.dart';
import '../models/result_model.dart';

class ReportService {
  static Future<void> generateAndDownloadReport({
    required BuildContext context,
    required PatientModel patient,
    required ScanResult result,
    required DateTime scanDate,
  }) async {
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              const SizedBox(width: 12),
              Text(AppLocalizations.tr('generating_pdf_report')),
            ]),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      final pdf = pw.Document();

      final riskColor = result.riskLevel == RiskLevel.high
          ? PdfColors.red700
          : result.riskLevel == RiskLevel.moderate
              ? PdfColors.orange700
              : PdfColors.green700;

      final riskLabel = result.riskLevel == RiskLevel.high
          ? 'HIGH RISK'
          : result.riskLevel == RiskLevel.moderate
              ? 'MODERATE RISK'
              : 'LOW RISK';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(AppLocalizations.tr('dentalscan_ai'),
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(AppLocalizations.tr('aipowered_oral_cancer_detection_report'),
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(AppLocalizations.tr('report_date'),
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                      pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Risk banner
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: riskColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(riskLabel,
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Cancer Probability: ${result.cancerProbability.toInt()}%',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Patient information
            pw.Text(AppLocalizations.tr('patient_information'),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(children: [
                _pdfRow('Patient Name', patient.name),
                _pdfRow('Age', '${patient.age} years'),
                _pdfRow('Mobile', patient.mobile),
                _pdfRow('Appointment Date', DateFormat('dd MMM yyyy').format(patient.date)),
                _pdfRow('Scan Date', DateFormat('dd MMM yyyy HH:mm').format(scanDate)),
                _pdfRow('Patient ID', patient.id),
              ]),
            ),
            pw.SizedBox(height: 20),

            // AI Analysis Results
            pw.Text(AppLocalizations.tr('ai_analysis_results'),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(children: [
                _pdfRow('Cancer Probability', '${result.cancerProbability.toInt()}%'),
                _pdfRow('Risk Level', riskLabel),
                _pdfRow('Detected Lesion', result.lesionType),
                if (result.diseaseName != null && result.diseaseName!.isNotEmpty && result.diseaseName != 'Normal')
                  _pdfRow('Disease Match', result.diseaseName!),
                if (result.diseaseMatchProbability != null && result.diseaseName != 'Normal')
                  _pdfRow('Disease Probability', '${result.diseaseMatchProbability!.toInt()}%'),
                if (result.lesionLocations.isNotEmpty)
                  _pdfRow('Affected Locations', result.lesionLocations.join(', ')),
              ]),
            ),
            pw.SizedBox(height: 20),

            // Per Image Analysis
            pw.Text(AppLocalizations.tr('perimage_analysis'),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeader('Image Type'),
                    _tableHeader('Finding'),
                    _tableHeader('Confidence'),
                  ],
                ),
                ...result.imageAnalysis.map((a) => pw.TableRow(
                  children: [
                    _tableCell(a.type),
                    _tableCell(a.finding),
                    _tableCell('${a.confidence}%'),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),

            // Clinical Recommendation
            pw.Text(AppLocalizations.tr('clinical_recommendation'),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue200),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(result.recommendation,
                  style: const pw.TextStyle(fontSize: 13)),
            ),
            pw.SizedBox(height: 20),

            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.yellow50,
                border: pw.Border.all(color: PdfColors.yellow700),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(AppLocalizations.tr('disclaimer'),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'This report is generated by AI and is for screening purposes only. '
                      'It should not replace professional medical diagnosis. '
                      'Please consult a qualified dental surgeon or oncologist for proper evaluation.',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );

      // Save/Download PDF
      final fileName = 'DentalScan_${patient.name.replaceAll(' ', '_')}_${DateFormat('ddMMMyyyy').format(scanDate)}.pdf';
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text,
          style: pw.TextStyle(color: PdfColors.white,
              fontWeight: pw.FontWeight.bold, fontSize: 11)),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
    );
  }
}