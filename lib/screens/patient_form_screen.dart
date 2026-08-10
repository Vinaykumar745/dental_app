import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../models/patient_model.dart';
import 'camera_screen.dart';

import '../services/api_service.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime tempSelectedDate = _selectedDate ?? firstDate;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -20,
                      child: Image.asset(
                        'assets/images/3d_tooth.png',
                        height: 160,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Select Appointment', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Choose Date', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppTheme.textDark,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: tempSelectedDate,
                  firstDate: firstDate,
                  lastDate: DateTime(now.year + 2),
                  onDateChanged: (date) {
                    tempSelectedDate = date;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCEL', style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(tempSelectedDate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.tr('please_select_a_date')),
            backgroundColor: AppTheme.danger));
      return;
    }
    setState(() => _isLoading = true);
    

    // Fetch existing patients to determine serial number
    int serialNum = 1;
    try {
      final patientsResult = await ApiService.getPatients();
      if (patientsResult.success && patientsResult.data != null) {
        final existingPatients = patientsResult.data as List<PatientModel>;
        serialNum = existingPatients.length + 1;
      }
    } catch (e) {
      debugPrint('Error fetching patients for serial number: $e');
    }

    final yearStr = DateTime.now().year.toString().substring(2); // Last 2 digits of current year
    final ageStr = _ageController.text.trim().padLeft(2, '0'); // 2 digit age
    final serialStr = serialNum.toString().padLeft(3, '0'); // 3 digit serial number
    
    final newId = '18$yearStr$ageStr$serialStr';

    await Future.delayed(const Duration(milliseconds: 300));
    final patient = PatientModel(
      id: newId,
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _selectedGender!,
      date: _selectedDate!,
      mobile: _mobileController.text.trim(),
      createdAt: DateTime.now(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CameraScreen(patient: patient)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.tr('patient_registration')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/dental_bg_3d.png'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_add, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.tr('new_patient'),
                            style: const TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(AppLocalizations.tr('fill_in_the_patient_details_below'),
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(children: [
                Container(width: 4, height: 20,
                  decoration: BoxDecoration(color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr('personal_information'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
              ]),
              const SizedBox(height: 16),
              _card(TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'Full Name', hintText: "Enter patient's full name",
                  prefixIcon: Icon(Icons.person, color: AppTheme.primary),
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter the patient name';
                  if (v.trim().length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              )),
              const SizedBox(height: 14),
              _card(TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w500),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Age', hintText: "Enter patient's age",
                  prefixIcon: Icon(Icons.cake, color: AppTheme.primary),
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter the age';
                  final age = int.tryParse(v);
                  if (age == null || age < 1 || age > 120) return 'Enter a valid age (1-120)';
                  return null;
                },
              )),
              const SizedBox(height: 14),
              _card(DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w500),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Gender', hintText: 'Select gender',
                  prefixIcon: Icon(Icons.people, color: AppTheme.primary),
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false,
                ),
                validator: (v) => v == null ? 'Please select a gender' : null,
              )),
              const SizedBox(height: 14),
              _card(TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w500),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'Mobile Number', hintText: AppLocalizations.tr('enter_10digit_mobile_number'),
                  prefixIcon: const Icon(Icons.phone, color: AppTheme.primary),
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false, counterText: ''),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter mobile number';
                  if (v.length != 10) return 'Enter a valid 10-digit mobile number';
                  return null;
                },
              )),
              const SizedBox(height: 14),
              _card(InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.tr('appointment_date'),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDate == null
                                ? 'Select date'
                                : DateFormat('dd MMM yyyy').format(_selectedDate!),
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate == null ? AppTheme.textGrey : AppTheme.textDark,
                                fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.textGrey),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After saving, you will be guided to capture 4 oral images for AI analysis.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                  ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.tr('save__continue'), style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}