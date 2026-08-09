import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRIVACY POLICY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data Processing Notice under DPDP Act & Health Data Guidelines',
              style: TextStyle(
                color: textGreyColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Data Collection & Processing Purposes',
              content: 'The Application processes personal and sensitive data solely for clinical risk stratification and patient care management:  Patient Identifiers: Name, age, sex, contact details, and hospital ID.  Clinical Data: Intra-oral photographic images/videos, tobacco/areca nut/alcohol habit history, and examination findings.  Technical & Audit Logs: Timestamps, device IDs, account credentials, and inference event logs to ensure security and medico-legal accountability.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '2. Data Minimisation & Security Safeguards',
              content: 'Minimisation: Images are cropped to regions of interest to exclude facial features unless clinically necessary.  Security: Data is encrypted at rest and in transit. Access is strictly role-based and governed by multi-factor authentication.  No Commercial Misuse: Personal data is never sold, rented, or used for advertising, credit scoring, employment screening, or insurance underwriting.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '3. Data Principal Rights',
              content: 'Patients (Data Principals) hold explicit rights regarding their personal data:  Right to access summary details of processed data and third-party disclosures.  Right to correction of inaccurate or incomplete health records.  Right to withdraw consent at any time without affecting ongoing standard care.  Right to request erasure (subject to mandatory medical record retention laws).',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '4. Data Retention & Breach Protocol',
              content: 'Retention: Identifiable health data is retained in accordance with statutory medical record retention timelines, after which it is erased or irreversibly anonymised.  Breach Notification: In the event of a personal data breach, notifications will be issued to affected individuals and the Data Protection Board of India per statutory requirements.',
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
