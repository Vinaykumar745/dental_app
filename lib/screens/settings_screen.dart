import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/localization_service.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_center_screen.dart';
import 'about_app_screen.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _darkModeEnabled;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = AppTheme.themeModeNotifier.value == ThemeMode.dark;
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.tr('logout')),
        content: Text(AppLocalizations.tr('are_you_sure_you_want_to_logout')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              await AuthState.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text(AppLocalizations.tr('logout')),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.tr('select_language'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextDark : AppTheme.textDark)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppLocalizations.languageNames.length,
            itemBuilder: (context, index) {
              final langCode = AppLocalizations.languageNames.keys.elementAt(index);
              final langName = AppLocalizations.languageNames[langCode]!;
              final isSelected = AppLocalizations.localeNotifier.value == langCode;
              return ListTile(
                title: Text(langName, style: TextStyle(color: isSelected ? AppTheme.primary : (isDark ? AppTheme.darkTextDark : AppTheme.textDark), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () async {
                  await AppLocalizations.changeLanguage(langCode);
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;
    final cardColor = isDark ? AppTheme.darkCardBg.withValues(alpha: 0.9) : AppTheme.cardBg.withValues(alpha: 0.9);
    final locale = AppLocalizations.localeNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('APP SETTINGS', textGreyColor),
            const SizedBox(height: 12),
            _settingsCard(
              cardColor: cardColor,
              children: [
                _toggleItem(
                  icon: Icons.dark_mode_outlined,
                  iconColor: Colors.deepPurple,
                  title: 'Dark Mode',
                  subtitle: 'Switch to dark theme',
                  value: _darkModeEnabled,
                  onChanged: (val) {
                    setState(() {
                      _darkModeEnabled = val;
                      AppTheme.themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                  textColor: textColor,
                  textGreyColor: textGreyColor,
                ),
                const Divider(height: 1, indent: 60),
                _toggleItem(
                  icon: Icons.notifications_none_rounded,
                  iconColor: Colors.amber,
                  title: 'Notifications',
                  subtitle: 'Receive alert notifications',
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                  },
                  textColor: textColor,
                  textGreyColor: textGreyColor,
                ),
                const Divider(height: 1, indent: 60),
                _actionItem(
                  icon: Icons.language,
                  iconColor: Colors.blue,
                  title: 'Language',
                  subtitle: AppLocalizations.languageNames[locale] ?? 'English',
                  textColor: textColor,
                  textGreyColor: textGreyColor,
                  onTap: () => _showLanguagePicker(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionLabel('LEGAL & SUPPORT', textGreyColor),
            const SizedBox(height: 12),
            _settingsCard(
              cardColor: cardColor,
              children: [
                _actionItem(
                  icon: Icons.gavel_outlined,
                  iconColor: Colors.deepOrange,
                  title: 'Terms & Conditions',
                  subtitle: 'Read our terms of use',
                  textColor: textColor,
                  textGreyColor: textGreyColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen())),
                ),
                const Divider(height: 1, indent: 60),
                _actionItem(
                  icon: Icons.shield_outlined,
                  iconColor: Colors.teal,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policies',
                  textColor: textColor,
                  textGreyColor: textGreyColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
                const Divider(height: 1, indent: 60),
                _actionItem(
                  icon: Icons.help_outline,
                  iconColor: Colors.green,
                  title: 'Help Center',
                  subtitle: 'FAQs and support',
                  textColor: textColor,
                  textGreyColor: textGreyColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                ),
                const Divider(height: 1, indent: 60),
                _actionItem(
                  icon: Icons.info_outline,
                  iconColor: Colors.grey.shade700,
                  title: 'About App',
                  subtitle: 'DentalScan AI v1.0.0',
                  textColor: textColor,
                  textGreyColor: textGreyColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppScreen())),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Logout Button
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.tr('logout'), style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color textGreyColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textGreyColor,
          letterSpacing: 1.0,
      )),
    );
  }

  Widget _settingsCard({required List<Widget> children, required Color cardColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _toggleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color textGreyColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textGreyColor, fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
        activeTrackColor: AppTheme.primaryLight.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color textGreyColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textGreyColor, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textGreyColor),
    );
  }
}
