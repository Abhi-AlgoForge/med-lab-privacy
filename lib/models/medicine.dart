class Medicine {
  final String id;
  final String name;
  final List<String> chemicalContents;
  final String generalUse;
  final List<HarmfulContent> harmfulContents;
  final List<String> agePrecautions;
  final DateTime scannedAt;
  final String? manufactureDate; // MM/YYYY
  final String? expiryDate; // MM/YYYY
  final String? interactionWarning;

  Medicine({
    String? id,
    required this.name,
    required this.chemicalContents,
    required this.generalUse,
    required this.harmfulContents,
    required this.agePrecautions,
    DateTime? scannedAt,
    this.manufactureDate,
    this.expiryDate,
    this.interactionWarning,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        scannedAt = scannedAt ?? DateTime.now();

  bool get hasHarmfulContent => harmfulContents.isNotEmpty;

  /// Returns true if the medicine is expired based on expiryDate (MM/YYYY)
  bool get isExpired {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    try {
      final parts = expiryDate!.split('/');
      if (parts.length != 2) return false;
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);
      // Medicine expires at the end of the given month
      final expiry = DateTime(year, month + 1, 0);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return false;
    }
  }

  Medicine copyWith({
    String? id,
    String? name,
    List<String>? chemicalContents,
    String? generalUse,
    List<HarmfulContent>? harmfulContents,
    List<String>? agePrecautions,
    DateTime? scannedAt,
    String? manufactureDate,
    String? expiryDate,
    String? interactionWarning,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      chemicalContents: chemicalContents ?? this.chemicalContents,
      generalUse: generalUse ?? this.generalUse,
      harmfulContents: harmfulContents ?? this.harmfulContents,
      agePrecautions: agePrecautions ?? this.agePrecautions,
      scannedAt: scannedAt ?? this.scannedAt,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      expiryDate: expiryDate ?? this.expiryDate,
      interactionWarning: interactionWarning ?? this.interactionWarning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chemicalContents': chemicalContents,
      'generalUse': generalUse,
      'harmfulContents': harmfulContents.map((h) => h.toJson()).toList(),
      'agePrecautions': agePrecautions,
      'scannedAt': scannedAt.toIso8601String(),
      'manufactureDate': manufactureDate,
      'expiryDate': expiryDate,
      'interactionWarning': interactionWarning,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unknown Medicine',
      chemicalContents: (json['chemicalContents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      generalUse: json['generalUse'] as String? ?? 'No information available',
      harmfulContents: (json['harmfulContents'] as List<dynamic>?)
              ?.map((e) => HarmfulContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      agePrecautions: (json['agePrecautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      scannedAt: json['scannedAt'] != null
          ? DateTime.tryParse(json['scannedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      manufactureDate: json['manufactureDate'] as String?,
      expiryDate: json['expiryDate'] as String?,
      interactionWarning: json['interactionWarning'] as String?,
    );
  }
}

class HarmfulContent {
  final String substance;
  final String description;
  final bool isSuspicious;

  HarmfulContent({
    required this.substance,
    required this.description,
    this.isSuspicious = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'substance': substance,
      'description': description,
      'isSuspicious': isSuspicious,
    };
  }

  factory HarmfulContent.fromJson(Map<String, dynamic> json) {
    return HarmfulContent(
      substance: json['substance'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isSuspicious: json['isSuspicious'] as bool? ?? false,
    );
  }
}
