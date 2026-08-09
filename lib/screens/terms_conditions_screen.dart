import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TERMS AND CONDITIONS OF USE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-Assisted Oral Cavity Screening Application for Oral Cancer Risk Estimation',
              style: TextStyle(
                color: textGreyColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Nature & Scope of Software',
              content: 'Adjunctive Tool: The application is a computer-aided triage and risk-stratification aid. It provides a statistical estimate based on pattern similarity to training data.  Not a Diagnosis: The Output carries no diagnostic authority. It is not a pathology report, radiology report, or clinical opinion. Histopathological confirmation via tissue biopsy remains the sole definitive diagnostic method.  Intended Audience: Authorised medical/dental practitioners and registered operators. Unsupervised or direct patient use is strictly prohibited.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '2. Practitioner Obligations & Clinical Responsibility',
              content: 'Primacy of Clinical Judgement: Clinical responsibility for the patient remains entirely with the Treating Practitioner. Where clinical judgment and the Output conflict, clinical judgment prevails.  Independent Examination: A complete conventional oral examination (visual inspection, palpation, lymph node check) must be performed and documented prior to viewing the Output.  Mandatory Action: A low-risk Output must never be used to defer, downgrade, or omit a clinically indicated biopsy or specialist referral. Clinically suspicious lesions must be biopsied regardless of the Output.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '3. Situations Where Output Is Void',
              content: 'The Output must be disregarded and not entered into medical records if:Image quality flags indicate low quality (amber or red).  The lesion is obscured by blood, slough, food debris, or prosthetics.  Operating conditions or devices deviate from validated standard operating procedures.  The patient falls outside the intended adult population.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '4. Data Governance & Prohibited Actions',
              content: 'Confidentiality: All patient data is strictly confidential. Capturing screen recordings, sharing images via personal messaging apps, or storing data on personal devices is prohibited.  System Integrity: Users shall not attempt to reverse-engineer, decompile, extract model weights, or circumvent security logs and hard-coded report disclaimers.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color textColor,
    required Color textGreyColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: textGreyColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
