import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;
    final cardColor = isDark ? AppTheme.darkCardBg : AppTheme.cardBg;

    final faqs = [
      {
        'q': 'How accurate is the AI detection?',
        'a': 'Our model is trained on a vast dataset of medical images and achieves high accuracy in identifying potential oral lesions. However, it is an assistive tool and not a replacement for clinical biopsies.'
      },
      {
        'q': 'How should I take a picture of a lesion?',
        'a': 'Ensure the area is well-lit, preferably with a flash. Keep the camera steady and focus clearly on the lesion. Avoid capturing unrelated facial features to maintain privacy.'
      },
      {
        'q': 'Is patient data secure?',
        'a': 'Yes. We employ end-to-end encryption for all images and patient records. Data is stored securely and complies with medical data protection standards.'
      },
      {
        'q': 'What does a "High Risk" result mean?',
        'a': 'A High Risk result indicates that the AI has detected visual patterns strongly correlated with malignant lesions. An immediate clinical examination and biopsy are recommended.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr('help_center')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SizedBox(height: 10),
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          ...faqs.map((faq) => Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    faq['q']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  iconColor: AppTheme.primary,
                  collapsedIconColor: textGreyColor,
                  children: [
                    Text(
                      faq['a']!,
                      style: TextStyle(color: textGreyColor, height: 1.4),
                    ),
                  ],
                ),
              )),
          SizedBox(height: 30),
          Text(
            'Contact Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: AppTheme.primary, size: 30),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Us',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'support@dentalscan.ai',
                        style: TextStyle(color: textGreyColor),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
