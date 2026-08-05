import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/localization_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../models/patient_model.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';
import 'tutorial_screen.dart';

class CameraScreen extends StatefulWidget {
  final PatientModel patient;
  const CameraScreen({super.key, required this.patient});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File?> _images = [null, null, null, null];
  int _currentStep = 0;
  bool _isPickingImage = false;

  final List<Map<String, dynamic>> _imageTypes = [
    {
      'title': 'Tongue',
      'subtitle': 'Top surface of tongue',
      'icon': Icons.medical_services,
      'color': const Color(0xFF7B1FA2),
      'instruction': 'Open your mouth wide and stick out your tongue.',
      'tip': 'Make sure the full top surface of the tongue is visible.',
    },
    {
      'title': 'Gums',
      'subtitle': 'Upper & lower gums',
      'icon': Icons.healing,
      'color': const Color(0xFFC62828),
      'instruction': 'Pull lips back to expose gums completely.',
      'tip': 'Good lighting helps capture gum color accurately.',
    },
    {
      'title': 'Floor of Mouth',
      'subtitle': 'Under the tongue',
      'icon': Icons.panorama_horizontal,
      'color': const Color(0xFF1565C0),
      'instruction': 'Lift tongue to roof of mouth to expose the floor.',
      'tip': 'This area is critical for early cancer detection.',
    },
    {
      'title': 'Buccal Mucosa',
      'subtitle': 'Inner cheek lining',
      'icon': Icons.face,
      'color': const Color(0xFF2E7D32),
      'instruction': 'Pull cheek outward gently to expose the inner lining.',
      'tip': 'Capture both left and right cheeks if possible.',
    },
  ];

  int get _capturedCount => _images.where((e) => e != null).length;
  bool get _allCaptured => _capturedCount == 4;

  Future<bool> _validateImage(int index, XFile photo) async {
    if (kIsWeb) return true; // MOCK ML KIT FOR WEB TO AVOID CRASH
    // REAL ML VALIDATION USING GOOGLE ML KIT
    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
      
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
      await imageLabeler.close();

      // Check if image contains any human anatomy or oral-related tags
      final validKeywords = ['mouth', 'lip', 'tooth', 'teeth', 'jaw', 'skin', 'face', 'head', 'flesh', 'gum', 'tongue', 'anatomy', 'human body', 'person'];
      
      bool hasAnatomy = false;
      List<String> detectedObjects = [];

      for (ImageLabel label in labels) {
        final text = label.label.toLowerCase();
        detectedObjects.add(text);
        for (String keyword in validKeywords) {
          if (text.contains(keyword)) {
            hasAnatomy = true;
            break;
          }
        }
      }

      // If no labels were detected at all, it's a very unclear image. Let's be strict.
      if (labels.isEmpty) hasAnatomy = false;

      // Also specifically reject "Paper", "Document", "Computer", "Laptop" even if 'skin' is lightly detected in background
      final invalidKeywords = ['paper', 'document', 'text', 'font', 'computer', 'laptop', 'car', 'vehicle', 'furniture', 'screen', 'monitor'];
      bool hasInvalid = false;
      for (String text in detectedObjects) {
        if (invalidKeywords.contains(text)) hasInvalid = true;
      }

      // Final decision: must have anatomy, OR must NOT have strictly invalid things. 
      // For safety and demonstration, let's reject if it lacks anatomy AND has invalid things, 
      // or simply reject if it lacks anatomy entirely.
      bool isValid = hasAnatomy && !hasInvalid; 
      
      if (!isValid) {
        String topDetection = detectedObjects.isNotEmpty ? detectedObjects.first : "Unclear Object";
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr('invalid_image')),
              ]),
              content: Text(
                'AI Analysis detected: "$topDetection".\n\nThis image does not appear to be a valid ${_imageTypes[index]['title']} image. Please avoid uploading unrelated images (e.g., paper, laptops, cars, scenery).',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.tr('try_again')),
                ),
              ],
            ),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("ML Kit error: $e");
      return true; // Fallback to true if ML kit fails to init
    }
  }

  Future<void> _pickFromCamera(int index) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (mounted) setState(() => _isPickingImage = false);
      if (photo != null && mounted) {
        setState(() => _isPickingImage = true); // keep loading overlay
        bool isValid = await _validateImage(index, photo);
        if (mounted) setState(() => _isPickingImage = false);
        
        if (isValid && mounted) {
          setState(() {
            _images[index] = File(photo.path);
            if (index < 3) _currentStep = index + 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPickingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery(int index) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (mounted) setState(() => _isPickingImage = false);
      if (photo != null && mounted) {
        setState(() => _isPickingImage = true); // keep loading overlay
        bool isValid = await _validateImage(index, photo);
        if (mounted) setState(() => _isPickingImage = false);
        
        if (isValid && mounted) {
          setState(() {
            _images[index] = File(photo.path);
            if (index < 3) _currentStep = index + 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPickingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showSourceDialog(int index) {
    final type = _imageTypes[index];
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(type['icon'] as IconData, color: type['color'] as Color, size: 22),
          const SizedBox(width: 8),
          Text('Capture ${type['title']}'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type['instruction'] as String,
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 16),
            // Camera option
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _pickFromCamera(index);
                  });
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(AppLocalizations.tr('take_photo_with_camera')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Gallery option
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _pickFromGallery(index);
                  });
                },
                icon: const Icon(Icons.photo_library),
                label: Text(AppLocalizations.tr('choose_from_gallery')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            if (_images[index] != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _images[index] = null);
                },
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                label: Text(AppLocalizations.tr('remove_image'),
                    style: const TextStyle(color: AppTheme.danger)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.tr('cancel')),
          ),
        ],
      ),
    );
  }

  void _proceedToResults() {
    if (!_allCaptured) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          patient: widget.patient,
          images: _images.map((e) => e!).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.tr('capture_oral_images')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: AppLocalizations.tr('how_to_capture'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TutorialScreen(patient: widget.patient),
                ),
              );
            },
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$_capturedCount/4',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress bar
              Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.tr('progress'),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12)),
                      Text('${(_capturedCount / 4 * 100).toInt()}% Complete',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _capturedCount / 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ]),
              ),

              // Patient info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(children: [
                  const Icon(Icons.person, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.patient.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(width: 12),
                  Container(
                      width: 1, height: 16, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  const Icon(Icons.cake, color: AppTheme.textGrey, size: 16),
                  const SizedBox(width: 4),
                  Text('${widget.patient.age} yrs',
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 13)),
                  const Spacer(),
                  Text(
                      'ID: ${widget.patient.id.substring(widget.patient.id.length - 6)}',
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 11)),
                ]),
              ),
              const Divider(height: 1),

              // Image list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (ctx, index) {
                    final type = _imageTypes[index];
                    final image = _images[index];
                    final isCurrent = index == _currentStep;
                    final isCaptured = image != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCaptured
                              ? AppTheme.success
                              : isCurrent
                                  ? type['color'] as Color
                                  : Colors.grey.shade200,
                          width: isCurrent || isCaptured ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: isCaptured
                                    ? AppTheme.success
                                    : (type['color'] as Color).withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: isCaptured
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 22)
                                : Icon(type['icon'] as IconData,
                                    color: type['color'] as Color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(type['title'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppTheme.textDark)),
                                  if (isCurrent && !isCaptured) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: type['color'] as Color,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(AppLocalizations.tr('current'),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ]),
                                const SizedBox(height: 2),
                                Text(type['subtitle'] as String,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textGrey)),
                                if (isCaptured) ...[
                                  const SizedBox(height: 4),
                                  Text(AppLocalizations.tr('image_captured'),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ],
                            ),
                          ),
                          if (isCaptured)
                            GestureDetector(
                              onTap: () => _showSourceDialog(index),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb
                                    ? Image.network(image.path, width: 56, height: 56, fit: BoxFit.cover)
                                    : Image.file(image, width: 56, height: 56, fit: BoxFit.cover),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _showSourceDialog(index),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: type['color'] as Color,
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10))),
                              child: Text(AppLocalizations.tr('capture'),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              // Bottom button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: Column(children: [
                  if (!_allCaptured)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                          'Capture ${4 - _capturedCount} more image${4 - _capturedCount == 1 ? '' : 's'} to continue',
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 13)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _allCaptured ? _proceedToResults : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _allCaptured
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              _allCaptured
                                  ? Icons.psychology
                                  : Icons.lock_outline,
                              color: _allCaptured
                                  ? Colors.white
                                  : AppTheme.textGrey,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                              _allCaptured
                                  ? 'Analyze with AI'
                                  : 'Capture all 4 images first',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: _allCaptured
                                      ? Colors.white
                                      : AppTheme.textGrey,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),

          // Loading overlay when picking image
          if (_isPickingImage)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primary),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.tr('opening_camera'),
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}