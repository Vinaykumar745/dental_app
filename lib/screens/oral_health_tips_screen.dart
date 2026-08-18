import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OralHealthTipsScreen extends StatelessWidget {
  const OralHealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oral Health Tips', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _TipCard(
            title: 'Brush Twice a Day',
            description: 'Brush your teeth at least twice a day with fluoride toothpaste for two minutes.',
            icon: Icons.clean_hands,
            color: Colors.blue,
          ),
          _TipCard(
            title: 'Floss Daily',
            description: 'Floss daily to remove plaque from places your toothbrush cannot reach.',
            icon: Icons.horizontal_rule,
            color: Colors.green,
          ),
          _TipCard(
            title: 'Avoid Tobacco',
            description: 'Tobacco use is a major cause of oral cancer and gum disease. Avoid it entirely.',
            icon: Icons.smoke_free,
            color: Colors.red,
          ),
          _TipCard(
            title: 'Limit Sugary Foods',
            description: 'Limit sugary snacks and drinks to protect your teeth from cavities.',
            icon: Icons.fastfood,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: AppTheme.textGrey, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
