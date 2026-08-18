enum RiskLevel { low, moderate, high }

class ScanResult {
  final double cancerProbability;
  final String lesionType;
  final List<String> lesionLocations;
  final RiskLevel riskLevel;
  final String recommendation;
  final List<ImageAnalysis> imageAnalysis;
  final DateTime scanDate;
  final String? diseaseName;
  final double? diseaseMatchProbability;
  final double modelConfidenceScore; // NEW: Overall confidence score (0-100)

  ScanResult({
    required this.cancerProbability,
    required this.lesionType,
    required this.lesionLocations,
    required this.riskLevel,
    required this.recommendation,
    required this.imageAnalysis,
    required this.scanDate,
    this.diseaseName,
    this.diseaseMatchProbability,
    this.modelConfidenceScore = 92.5, // Default for mock
  });

  Map<String, dynamic> toMap() {
    return {
      'cancerProbability': cancerProbability,
      'lesionType': lesionType,
      'lesionLocations': lesionLocations,
      'riskLevel': riskLevel.name,
      'recommendation': recommendation,
      'imageAnalysis': imageAnalysis.map((e) => e.toMap()).toList(),
      'scanDate': scanDate.toIso8601String(),
      'modelConfidenceScore': modelConfidenceScore,
      if (diseaseName != null) 'diseaseName': diseaseName,
      if (diseaseMatchProbability != null)
        'diseaseMatchProbability': diseaseMatchProbability,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    final riskStr = map['riskLevel'] ?? 'low';
    final riskLevel = riskStr == 'high'
        ? RiskLevel.high
        : riskStr == 'moderate'
            ? RiskLevel.moderate
            : RiskLevel.low;

    final imageAnalysis = (map['imageAnalysis'] as List? ?? [])
        .map((a) => ImageAnalysis(
              type: a['type'] ?? '',
              finding: a['finding'] ?? '',
              confidence: a['confidence'] ?? 0,
            ))
        .toList();

    return ScanResult(
      cancerProbability: (map['cancerProbability'] ?? 0).toDouble(),
      lesionType: map['lesionType'] ?? '',
      lesionLocations: List<String>.from(map['lesionLocations'] ?? []),
      riskLevel: riskLevel,
      recommendation: map['recommendation'] ?? '',
      imageAnalysis: imageAnalysis,
      scanDate: DateTime.tryParse(map['scanDate'] ?? '') ?? DateTime.now(),
      diseaseName: map['diseaseName'],
      diseaseMatchProbability:
          (map['diseaseMatchProbability'] as num?)?.toDouble(),
      modelConfidenceScore: (map['modelConfidenceScore'] as num?)?.toDouble() ?? 85.0,
    );
  }
}

class ImageAnalysis {
  final String type;
  final String finding;
  final int confidence;
  final List<double>? boundingBox; // [x, y, width, height]

  ImageAnalysis({
    required this.type,
    required this.finding,
    required this.confidence,
    this.boundingBox,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type, 
      'finding': finding, 
      'confidence': confidence,
      if (boundingBox != null) 'boundingBox': boundingBox,
    };
  }
}
