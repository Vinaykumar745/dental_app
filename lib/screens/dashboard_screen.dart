import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient_model.dart';
import '../models/result_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../services/auth_state.dart';
import '../services/localization_service.dart';
import 'patient_form_screen.dart';
import 'auth_screen.dart';
import 'model_training_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_center_screen.dart';
import 'about_app_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/report_service.dart';
import 'privacy_policy_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<_HistoryItem> _history = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiPatientsResult = await ApiService.getPatients();
      final localPatients = apiPatientsResult.success ? (apiPatientsResult.data as List<PatientModel>) : <PatientModel>[];
      final statsResult = await ApiService.getDashboardStats();

      if (mounted) {
        final List<_HistoryItem> items = [];

        for (final patient in localPatients) {
          final apiScansResult = await ApiService.getPatientScans(patient.id);
          final patientScans = apiScansResult.success 
              ? (apiScansResult.data as List<dynamic>).map((e) => ScanResult.fromMap(e)).toList() 
              : <ScanResult>[];

          if (patientScans.isNotEmpty) {
            final latestScan = patientScans.last; // Get most recent
            try {
              items.add(
                  _HistoryItem(patient: patient, result: latestScan, date: latestScan.scanDate));
            } catch (e) {
              debugPrint('Error loading scan for ${patient.name}: $e');
            }
          }
        }

        // Sort by date descending
        items.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          _history = items;
          _stats = statsResult.success ? statsResult.data : {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.background;
    final navColor = isDark ? AppTheme.darkCardBg : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.tr('dentalscan_ai')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: AppLocalizations.tr('refresh'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text(AppLocalizations.tr('loading_dashboard'),
                      style: TextStyle(color: AppTheme.textGrey)),
                ],
              ),
            )
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _HomeTab(
                  userName: AuthState.userName,
                  history: _history,
                  stats: _stats,
                  onRefresh: _loadData,
                ),
                _PatientsTab(
                  history: _history,
                  onRefresh: _loadData,
                ),
                _ProfileTab(onLogout: _logout),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: navColor,
        indicatorColor: AppTheme.primary.withOpacity(0.12),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
            label: AppLocalizations.tr('dashboard'),
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: AppTheme.primary),
            label: AppLocalizations.tr('patients'),
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: AppLocalizations.tr('profile'),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PatientFormScreen()),
                );
                _loadData();
              },
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(AppLocalizations.tr('new_scan'),
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOME TAB
// ══════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final String? userName;
  final List<_HistoryItem> history;
  final Map<String, dynamic> stats;
  final VoidCallback onRefresh;

  const _HomeTab({
    required this.userName,
    required this.history,
    required this.stats,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDarkColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;
    final cardColor = isDark ? AppTheme.darkCardBg : Colors.white;

    final highRisk = stats['highRisk'] ?? 0;
    final modRisk = stats['moderateRisk'] ?? 0;
    final lowRisk = stats['lowRisk'] ?? 0;
    final totalScans = stats['totalScans'] ?? history.length;
    final totalPatients = stats['totalPatients'] ?? history.length;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital,
                          color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.tr('welcome_back_1'),
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('Dr. ${userName ?? 'Doctor'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ]),
                  SizedBox(height: 16),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$totalPatients patient${totalPatients != 1 ? 's' : ''} • $totalScans scan${totalScans != 1 ? 's' : ''} recorded',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Stats
            Row(children: [
              _StatCard(label: AppLocalizations.tr('high_risk'), value: highRisk.toString(),
                  color: AppTheme.danger, icon: Icons.warning_rounded),
              SizedBox(width: 10),
              _StatCard(label: AppLocalizations.tr('moderate'), value: modRisk.toString(),
                  color: AppTheme.warning, icon: Icons.info_rounded),
              SizedBox(width: 10),
              _StatCard(label: AppLocalizations.tr('low_risk'), value: lowRisk.toString(),
                  color: AppTheme.success, icon: Icons.check_circle_rounded),
            ]),
            SizedBox(height: 20),

            // Quick actions
            _sectionTitle('Quick Actions', textDarkColor),
            SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_circle,
                  label: AppLocalizations.tr('new_scan'),
                  color: AppTheme.primary,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PatientFormScreen()),
                    );
                    onRefresh();
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.history,
                  label: AppLocalizations.tr('refresh'),
                  color: AppTheme.accent,
                  onTap: onRefresh,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.model_training,
                  label: AppLocalizations.tr('ai_training'),
                  color: AppTheme.warning,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ModelTrainingScreen()),
                    );
                  },
                ),
              ),
            ]),
            SizedBox(height: 20),

            // Recent scans
            _sectionTitle('Recent Scans', textDarkColor),
            SizedBox(height: 10),
            if (history.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.medical_services,
                        size: 48, color: textGreyColor.withOpacity(0.5)),
                    SizedBox(height: 12),
                    Text(AppLocalizations.tr('no_scans_yet'),
                        style: TextStyle(
                            fontSize: 16,
                            color: textGreyColor,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text(AppLocalizations.tr('tap_new_scan_to_get_started'),
                        style: TextStyle(
                            fontSize: 13, color: textGreyColor.withOpacity(0.8))),
                  ],
                ),
              )
            else
              ...history.map((item) => _ScanCard(item: item)).toList(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color textDarkColor) {
    return Row(children: [
      Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
              color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
      SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: textDarkColor)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// PATIENTS TAB
// ══════════════════════════════════════════════════════════════
class _PatientsTab extends StatefulWidget {
  final List<_HistoryItem> history;
  final VoidCallback onRefresh;
  const _PatientsTab({required this.history, required this.onRefresh});

  @override
  State<_PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<_PatientsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;
    final cardColor = isDark ? AppTheme.darkCardBg : AppTheme.cardBg;

    final filtered = widget.history.where((item) {
      final q = _searchQuery.toLowerCase();
      return item.patient.name.toLowerCase().contains(q) ||
          item.patient.mobile.contains(q) ||
          item.result.lesionType.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          color: AppTheme.primary,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.history.length} Patient${widget.history.length != 1 ? 's' : ''} Found',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.tr('search_by_name_mobile_or_lesion'),
                    hintStyle: TextStyle(color: textGreyColor),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: textGreyColor.withOpacity(0.5)),
                      SizedBox(height: 16),
                      Text(AppLocalizations.tr('no_patients_yet'),
                          style: TextStyle(
                              fontSize: 18,
                              color: textGreyColor,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text(AppLocalizations.tr('add_a_new_patient_scan_to_get_started'),
                          style: TextStyle(
                              fontSize: 14, color: textGreyColor.withOpacity(0.8))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => widget.onRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final rc = item.result.riskLevel == RiskLevel.high
                          ? AppTheme.danger
                          : item.result.riskLevel == RiskLevel.moderate
                              ? AppTheme.warning
                              : AppTheme.success;
                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: rc.withOpacity(0.2), width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: rc.withOpacity(0.15),
                            child: Text(
                              item.patient.name[0].toUpperCase(),
                              style: TextStyle(
                                  color: rc,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18),
                            ),
                          ),
                          title: Text(item.patient.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.cake_outlined,
                                    size: 12, color: textGreyColor),
                                SizedBox(width: 4),
                                Text('Age: ${item.patient.age}',
                                    style: TextStyle(
                                        fontSize: 12, color: textGreyColor)),
                                SizedBox(width: 10),
                                Icon(Icons.phone_outlined,
                                    size: 12, color: textGreyColor),
                                SizedBox(width: 4),
                                Text(item.patient.mobile,
                                    style: TextStyle(
                                        fontSize: 12, color: textGreyColor)),
                              ]),
                              SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: rc.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(item.result.lesionType,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: rc,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: rc.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.result.cancerProbability.toInt()}%',
                                  style: TextStyle(
                                      color: rc,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM').format(item.date),
                                style: TextStyle(
                                    fontSize: 11, color: textGreyColor),
                              ),
                            ],
                          ),
                          onTap: () => _showDetail(context, item),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, _HistoryItem item) {
    final rc = item.result.riskLevel == RiskLevel.high
        ? AppTheme.danger
        : item.result.riskLevel == RiskLevel.moderate
            ? AppTheme.warning
            : AppTheme.success;
    final riskLabel = item.result.riskLevel == RiskLevel.high
        ? 'HIGH RISK'
        : item.result.riskLevel == RiskLevel.moderate
            ? 'MODERATE RISK'
            : 'LOW RISK';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: rc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: rc.withOpacity(0.3)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: rc.withOpacity(0.2),
                    child: Text(item.patient.name[0].toUpperCase(),
                        style: TextStyle(
                            fontSize: 22, color: rc, fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.patient.name,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                        Text('Age: ${item.patient.age} • ${item.patient.mobile}',
                            style: const TextStyle(
                                color: AppTheme.textGrey, fontSize: 13)),
                        SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rc, borderRadius: BorderRadius.circular(6)),
                          child: Text(riskLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(children: [
                        _row2('Scan Date', DateFormat('dd MMM yyyy').format(item.date)),
                        _row2('Cancer Probability', '${item.result.cancerProbability.toInt()}%'),
                        _row2('Lesion Type', item.result.lesionType),
                        if (item.result.diseaseName != null && item.result.diseaseName!.isNotEmpty && item.result.diseaseName != 'Normal')
                          _row2('Disease', item.result.diseaseName!),
                        if (item.result.diseaseMatchProbability != null && item.result.diseaseName != 'Normal')
                          _row2('Disease Match', '${item.result.diseaseMatchProbability!.toInt()}%'),
                        if (item.result.lesionLocations.isNotEmpty)
                          _row2('Locations', item.result.lesionLocations.join(', ')),
                      ]),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: rc.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: rc.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.medical_services, color: rc, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.tr('clinical_recommendation'),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.textDark)),
                              SizedBox(height: 4),
                              Text(item.result.recommendation,
                                  style: TextStyle(fontSize: 13, color: rc)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(height: 12),
                    // Download Report button
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ReportService.generateAndDownloadReport(
                          context: context,
                          patient: item.patient,
                          result: item.result,
                          scanDate: item.date,
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: Text(AppLocalizations.tr('download_pdf_report')),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row2(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROFILE TAB
// ══════════════════════════════════════════════════════════════
class _ProfileTab extends StatefulWidget {
  final VoidCallback onLogout;
  const _ProfileTab({required this.onLogout});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _notificationsEnabled = true;
  late bool _darkModeEnabled;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = AppTheme.themeModeNotifier.value == ThemeMode.dark;
    _loadRating();
  }

  Future<void> _loadRating() async {
    final rating = await LocalDatabaseService.getAverageRating();
    if (mounted) {
      setState(() {
        _averageRating = rating;
      });
    }
  }

  Future<void> _showAvatarPicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
              title: Text(AppLocalizations.tr('take_a_photo')),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    await AuthState.updateAvatar(picked.path);
                    setState(() {});
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.tr('camera_not_available_on_this_device'))),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.accent),
              title: Text(AppLocalizations.tr('choose_from_gallery')),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    await AuthState.updateAvatar(picked.path);
                    setState(() {});
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.tr('gallery_not_available'))),
                  );
                }
              },
            ),
            const Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(AppLocalizations.tr('predefined_avatars'), style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _presetAvatar('preset:doc_f', 'assets/images/avatar_doc_f.png'),
                  _presetAvatar('preset:doc_m', 'assets/images/avatar_doc_m.png'),
                  _presetAvatar('preset:bear', 'assets/images/avatar_bear.png'),
                  _presetAvatar('preset:diverse', 'assets/images/avatar_diverse.png'),
                  _presetAvatar('preset:cat', 'assets/images/avatar_cat.png'),
                  _presetAvatar('preset:rabbit', 'assets/images/avatar_rabbit.png'),
                  _presetAvatar('preset:duck', 'assets/images/avatar_duck.png'),
                  _presetAvatar('preset:senior_m', 'assets/images/avatar_senior_m.png'),
                  _presetAvatar('preset:hijab', 'assets/images/avatar_hijab.png'),
                  _presetAvatar('preset:nurse_f', 'assets/images/avatar_nurse_f.png'),
                  _presetAvatar('preset:diverse_m', 'assets/images/avatar_diverse_m.png'),
                  _presetAvatar('preset:doc_diverse', 'assets/images/avatar_doc_diverse.png'),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
              title: Text(AppLocalizations.tr('remove_avatar'), style: TextStyle(color: AppTheme.danger)),
              onTap: () async {
                Navigator.pop(ctx);
                await AuthState.updateAvatar('');
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetAvatar(String id, String assetPath) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await AuthState.updateAvatar(id);
        setState(() {});
      },
      child: CircleAvatar(
        radius: 32,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage(assetPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthState.userName ?? 'Doctor';
    final email = AuthState.userEmail ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'D';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;
    final cardColor = isDark ? AppTheme.darkCardBg : AppTheme.cardBg;

    // Load Avatar Image Provider
    ImageProvider? avatarProvider;

    if (AuthState.avatarPath != null && AuthState.avatarPath!.isNotEmpty) {
      if (AuthState.avatarPath!.startsWith('preset:')) {
        String assetPath = 'assets/images/avatar_doc_f.png'; // default
        switch (AuthState.avatarPath!) {
          case 'preset:doc_m': assetPath = 'assets/images/avatar_doc_m.png'; break;
          case 'preset:bear': assetPath = 'assets/images/avatar_bear.png'; break;
          case 'preset:diverse': assetPath = 'assets/images/avatar_diverse.png'; break;
          case 'preset:cat': assetPath = 'assets/images/avatar_cat.png'; break;
          case 'preset:rabbit': assetPath = 'assets/images/avatar_rabbit.png'; break;
          case 'preset:duck': assetPath = 'assets/images/avatar_duck.png'; break;
          case 'preset:senior_m': assetPath = 'assets/images/avatar_senior_m.png'; break;
          case 'preset:hijab': assetPath = 'assets/images/avatar_hijab.png'; break;
          case 'preset:nurse_f': assetPath = 'assets/images/avatar_nurse_f.png'; break;
          case 'preset:diverse_m': assetPath = 'assets/images/avatar_diverse_m.png'; break;
          case 'preset:doc_diverse': assetPath = 'assets/images/avatar_doc_diverse.png'; break;
        }
        avatarProvider = AssetImage(assetPath);
      } else {
        if (kIsWeb) {
          if (AuthState.avatarPath!.startsWith('blob:')) {
             avatarProvider = NetworkImage(AuthState.avatarPath!);
          } else {
             // Fallback if not a blob URL
             avatarProvider = NetworkImage(AuthState.avatarPath!);
          }
        } else {
          avatarProvider = FileImage(File(AuthState.avatarPath!));
        }
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 60, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.tr('profile'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () => _showEditProfile(context),
                    )
                  ],
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: avatarProvider != null
                            ? CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: avatarProvider,
                              )
                            : CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.accent,
                                child: Text(initials,
                                    style: const TextStyle(
                                        fontSize: 40,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Dr. $name',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text(email,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14)),
                SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(AppLocalizations.tr('senior_dental_surgeon'),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          
          // Overlapping Stats Card
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('Patients', '1,284', Icons.people_outline, Colors.blue, textColor, textGreyColor),
                    Container(width: 1, height: 40, color: Colors.grey.shade200),
                    _statItem('Scans', '3,492', Icons.document_scanner_outlined, Colors.purple, textColor, textGreyColor),
                    Container(width: 1, height: 40, color: Colors.grey.shade200),
                    _statItem('Rating', _averageRating > 0 ? _averageRating.toStringAsFixed(1) : '-', Icons.star_outline, Colors.orange, textColor, textGreyColor),
                  ],
                ),
              ),
            ),
          ),

          // Settings Section
          ValueListenableBuilder<String>(
            valueListenable: AppLocalizations.localeNotifier,
            builder: (context, locale, childWidget) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(AppLocalizations.tr('preferences'), textGreyColor),
                    SizedBox(height: 12),
                    _settingsCard(
                      cardColor: cardColor,
                      children: [
                        _toggleItem(
                          icon: Icons.notifications_active_outlined,
                          iconColor: Colors.amber,
                          title: AppLocalizations.tr('push_notifications'),
                          subtitle: AppLocalizations.tr('get_alerts'),
                          value: _notificationsEnabled,
                          textColor: textColor,
                          textGreyColor: textGreyColor,
                          onChanged: (v) => setState(() => _notificationsEnabled = v),
                        ),
                        const Divider(height: 1, indent: 60),
                        _toggleItem(
                          icon: Icons.dark_mode_outlined,
                          iconColor: Colors.indigo,
                          title: AppLocalizations.tr('dark_mode'),
                          subtitle: AppLocalizations.tr('switch_dark'),
                          value: _darkModeEnabled,
                          textColor: textColor,
                          textGreyColor: textGreyColor,
                          onChanged: (v) {
                            setState(() => _darkModeEnabled = v);
                            AppTheme.themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                          },
                        ),
                        const Divider(height: 1, indent: 60),
                        _actionItem(
                          icon: Icons.language,
                          iconColor: Colors.purple,
                          title: AppLocalizations.tr('language'),
                          subtitle: AppLocalizations.languageNames[locale] ?? 'English',
                          textColor: textColor,
                          textGreyColor: textGreyColor,
                          onTap: () => _showLanguagePicker(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    _sectionLabel(AppLocalizations.tr('account_security'), textGreyColor),
                    SizedBox(height: 12),
                    _settingsCard(
                      cardColor: cardColor,
                      children: [
                        _actionItem(
                          icon: Icons.lock_outline,
                          iconColor: Colors.teal,
                          title: AppLocalizations.tr('change_password'),
                          subtitle: AppLocalizations.tr('update_credentials'),
                          textColor: textColor,
                          textGreyColor: textGreyColor,
                          onTap: () => _showChangePassword(context),
                        ),
                        const Divider(height: 1, indent: 60),
                        _actionItem(
                          icon: Icons.shield_outlined,
                          iconColor: Colors.blue,
                          title: AppLocalizations.tr('privacy_policy'),
                          subtitle: AppLocalizations.tr('read_policies'),
                          textColor: textColor,
                          textGreyColor: textGreyColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    _sectionLabel(AppLocalizations.tr('support'), textGreyColor),
                    SizedBox(height: 12),
                    _settingsCard(
                      cardColor: cardColor,
                      children: [
                        _actionItem(
                          icon: Icons.help_outline,
                          iconColor: Colors.green,
                          title: AppLocalizations.tr('help_center'),
                          subtitle: AppLocalizations.tr('faq_support'),
                          textColor: textColor,
                          textGreyColor: textGreyColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                        ),
                        const Divider(height: 1, indent: 60),
                        _actionItem(
                          icon: Icons.info_outline,
                          iconColor: Colors.grey.shade700,
                          title: AppLocalizations.tr('about_app'),
                          subtitle: 'DentalScan AI v1.0.0',
                          textColor: textColor,
                          textGreyColor: textGreyColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppScreen())),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Logout Button
                    GestureDetector(
                      onTap: widget.onLogout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text(AppLocalizations.tr('log_out'), style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color, Color textColor, Color textGreyColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        Text(label, style: TextStyle(fontSize: 12, color: textGreyColor)),
      ],
    );
  }

  Widget _sectionLabel(String label, Color textGreyColor) {
    return Text(label, style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textGreyColor,
        letterSpacing: 1.0,
        backgroundColor: Colors.transparent,
    ));
  }

  Widget _settingsCard({required List<Widget> children, required Color cardColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textGreyColor)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textGreyColor)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textGreyColor),
    );
  }

  void _showEditProfile(BuildContext context) {
    final nameController = TextEditingController(text: AuthState.userName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.tr('edit_profile'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextDark : AppTheme.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              style: TextStyle(color: isDark ? AppTheme.darkTextDark : AppTheme.textDark),
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await AuthState.save(
                  token: AuthState.token ?? '',
                  name: nameController.text.trim(),
                  email: AuthState.userEmail ?? '',
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(AppLocalizations.tr('save')),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.tr('change_password'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextDark : AppTheme.textDark)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                style: TextStyle(color: isDark ? AppTheme.darkTextDark : AppTheme.textDark),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                style: TextStyle(color: isDark ? AppTheme.darkTextDark : AppTheme.textDark),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                style: TextStyle(color: isDark ? AppTheme.darkTextDark : AppTheme.textDark),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v != newController.text ? 'Mismatch' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr('password_updated_successfully')),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(AppLocalizations.tr('change')),
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
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;
    final cardColor = isDark ? AppTheme.darkCardBg : Colors.white;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: textGreyColor)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final _HistoryItem item;
  const _ScanCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDarkColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;
    final cardColor = isDark ? AppTheme.darkCardBg : Colors.white;

    final rc = item.result.riskLevel == RiskLevel.high
        ? AppTheme.danger
        : item.result.riskLevel == RiskLevel.moderate
            ? AppTheme.warning
            : AppTheme.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
              color: rc.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(
              item.result.riskLevel == RiskLevel.high
                  ? Icons.warning_rounded
                  : item.result.riskLevel == RiskLevel.moderate
                      ? Icons.info_rounded
                      : Icons.check_circle_rounded,
              color: rc, size: 24),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.patient.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textDarkColor,
                      fontSize: 14)),
              Text(item.result.lesionType,
                  style: TextStyle(
                      fontSize: 12, color: textGreyColor)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${item.result.cancerProbability.toInt()}%',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: rc)),
            Text(DateFormat('dd MMM').format(item.date),
                style: TextStyle(fontSize: 11, color: textGreyColor)),
          ],
        ),
      ]),
    );
  }
}

class _HistoryItem {
  final PatientModel patient;
  final ScanResult result;
  final DateTime date;
  _HistoryItem(
      {required this.patient, required this.result, required this.date});
}