import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/medicine.dart';
import '../models/bill_analysis.dart';

class GeminiService {
  late final GenerativeModel _model;
  static String? _cachedKey;

  GeminiService() {
    final key = _cachedKey ?? _fallbackKey;
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: key,
    );
  }

  // Build-time fallback only (pass via --dart-define=GEMINI_API_KEY=...)
  static const String _fallbackKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Call once at app startup (before creating GeminiService instances).
  /// Fetches the key from Firebase Remote Config so you can rotate it
  /// from the Firebase Console without shipping an update.
  static Future<void> initialize() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await rc.setDefaults({'gemini_api_key': _fallbackKey});
      await rc.fetchAndActivate();
      final remoteKey = rc.getString('gemini_api_key');
      if (remoteKey.isNotEmpty) _cachedKey = remoteKey;
    } catch (_) {
      // Remote Config unavailable — fall back to build-time key
    }
  }

  /// Analyze medicine image and extract detailed information
  Future<Medicine> analyzeMedicineImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
IMPORTANT: First, verify the image. If the image does NOT show a medicine, tablet, pill, medicine box, medicine packaging, or pharmaceutical product, return this exact JSON:
{
  "name": "Not a Medicine",
  "chemicalContents": [],
  "generalUse": "The uploaded image does not appear to be a medicine or pharmaceutical product. Please upload a clear photo of a medicine, tablet, pill, or medicine packaging.",
  "harmfulContents": [],
  "agePrecautions": [],
  "manufactureDate": null,
  "expiryDate": null
}

Also return the above if the image is blurry, unclear, contains inappropriate/illegal content, or is unreadable.

If the image IS a valid medicine/pharmaceutical product, analyze it and provide detailed information in JSON format.

Please identify:
1. Medicine name (brand name and/or generic name)
2. Chemical contents/Active ingredients (list all compounds)
3. General use (what condition it treats)
4. Harmful content analysis (check for any suspicious or potentially harmful substances that might be overlooked for profit. Mark suspicious ones with isSuspicious: true)
5. Age-specific precautions (recommended age, warnings for children/elderly, etc.)
6. Manufacturing date (MFD) if visible on packaging — format as MM/YYYY
7. Expiry date (EXP) if visible on packaging — format as MM/YYYY

Return ONLY a valid JSON object with this exact structure:
{
  "name": "Medicine Name",
  "chemicalContents": ["ingredient1", "ingredient2"],
  "generalUse": "Description of what this medicine is used for",
  "harmfulContents": [
    {
      "substance": "substance name",
      "description": "why it could be harmful",
      "isSuspicious": true/false
    }
  ],
  "agePrecautions": ["precaution 1", "precaution 2"],
  "manufactureDate": "MM/YYYY or null if not visible",
  "expiryDate": "MM/YYYY or null if not visible"
}

If you can partially identify the medicine, provide the best analysis possible based on visible text or markings.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      // Extract JSON from response (remove markdown code blocks if present)
      String jsonText = text.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Parse JSON
      final json = Medicine.fromJson(
        Map<String, dynamic>.from(
          // Parse the JSON string
          _parseJson(jsonText),
        ),
      );

      return json;
    } catch (e) {
      throw Exception('Failed to analyze medicine: $e');
    }
  }

  /// Analyze prescription image and extract medication information
  Future<List<PrescriptionMedicine>> analyzePrescription(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
IMPORTANT: First, verify the image. If the image does NOT show a medical prescription, doctor's note, or medication order, return this exact JSON:
[
  {
    "medicineName": "Not a Prescription",
    "timing": "morning",
    "beforeEating": true
  }
]

Also return the above if the image is blurry, unclear, contains inappropriate/illegal content, or is unreadable.

If the image IS a valid prescription, analyze it and extract all medication information.

For each medicine prescribed, identify:
1. Medicine name
2. When to take it (morning/afternoon/night) - map to one of these three options
3. Whether to take before or after eating

Return ONLY a valid JSON array with this structure:
[
  {
    "medicineName": "Name of medicine",
    "timing": "morning" | "afternoon" | "night",
    "beforeEating": true/false
  }
]

If timing is not specified, use "morning" as default.
If eating preference is not specified, use "beforeEating": true as default.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      // Extract JSON from response
      String jsonText = text.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Parse JSON array
      final List<dynamic> jsonList = _parseJson(jsonText) as List<dynamic>;
      
      return jsonList
          .map((json) => PrescriptionMedicine.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to analyze prescription: $e');
    }
  }

  /// Check drug interactions between a new medicine and previously scanned medicines
  Future<String?> checkDrugInteractions({
    required Medicine newMedicine,
    required List<Medicine> history,
  }) async {
    try {
      if (history.isEmpty) return null;

      final previousMeds = history
          .take(20) // Limit to last 20 to keep prompt manageable
          .map((m) =>
              '- ${m.name} (${m.chemicalContents.join(", ")})')
          .join('\n');

      final prompt = '''
You are a pharmaceutical expert. Check for potential drug interactions.

NEW MEDICINE:
Name: ${newMedicine.name}
Ingredients: ${newMedicine.chemicalContents.join(', ')}

PREVIOUSLY SCANNED MEDICINES:
$previousMeds

Analyze if the new medicine could interact negatively with any of the previously scanned medicines.

If there ARE potential interactions, return a concise warning (2-4 sentences) explaining the risks. Be specific about which medicines interact and why.

If there are NO significant interactions, return exactly: NO_INTERACTION

Return ONLY the warning text or NO_INTERACTION. No JSON, no markdown.
''';

      final response =
          await _model.generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim();

      if (text.isEmpty || text == 'NO_INTERACTION' || text.contains('NO_INTERACTION')) {
        return null;
      }
      return text;
    } catch (_) {
      return null;
    }
  }

  /// Check drug interactions for a prescription against previously scanned medicines
  Future<String?> checkPrescriptionInteractions({
    required List<PrescriptionMedicine> newPrescription,
    required List<String> priorMedicineNames,
  }) async {
    try {
      if (priorMedicineNames.isEmpty) return null;

      final newMeds =
          newPrescription.map((p) => '- ${p.medicineName}').join('\n');
      final priorMeds =
          priorMedicineNames.map((n) => '- $n').join('\n');

      final prompt = '''
You are a pharmaceutical expert. Check for potential drug interactions.

NEWLY PRESCRIBED MEDICINES:
$newMeds

PREVIOUSLY USED MEDICINES:
$priorMeds

Analyze if any of the newly prescribed medicines could interact negatively with the previously used medicines.

If there ARE potential interactions, return a concise warning (2-4 sentences) explaining the risks.

If there are NO significant interactions, return exactly: NO_INTERACTION

Return ONLY the warning text or NO_INTERACTION. No JSON, no markdown.
''';

      final response =
          await _model.generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim();

      if (text.isEmpty || text == 'NO_INTERACTION' || text.contains('NO_INTERACTION')) {
        return null;
      }
      return text;
    } catch (_) {
      return null;
    }
  }

  dynamic _parseJson(String jsonText) {
    try {
      return jsonDecode(jsonText);
    } catch (e) {
      // If JSON parsing fails, return a default structure
      if (jsonText.contains('[')) {
        return <dynamic>[];
      } else {
        return <String, dynamic>{
          'name': 'Unknown',
          'chemicalContents': <String>[],
          'generalUse': 'Unable to analyze. Please ensure the image is clear and shows medicine information.',
          'harmfulContents': <dynamic>[],
          'agePrecautions': <String>[],
        };
      }
    }
  }

  /// Analyze a medical bill image for irregularities
  Future<BillAnalysis> analyzeBill(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
IMPORTANT: First, verify the image. If the image does NOT show a medical bill, hospital bill, pharmacy receipt, or healthcare invoice, return this exact JSON:
{
  "hospitalName": "Not a Medical Bill",
  "summary": "The uploaded image does not appear to be a medical bill or healthcare invoice. Please upload a clear photo of a medical bill, hospital bill, or pharmacy receipt.",
  "totalAmount": null,
  "overallVerdict": "clean",
  "recommendation": "Please upload a clear image of a medical bill for analysis.",
  "issues": []
}

Also return the above if the image is blurry, unclear, contains inappropriate/illegal content, or is unreadable.

If the image IS a valid medical bill, proceed with analysis.

You are a medical billing expert. Analyze this medical/hospital bill image and identify any potential irregularities or issues.

Look carefully for:
1. Items that seem overcharged compared to standard market rates
2. Double-charged items (same item or service charged more than once)
3. Unnecessary charges (items or services not relevant to the treatment)
4. Items with unusually high prices compared to standard rates
5. Vague or missing item descriptions that could hide inflated charges
6. Medications or procedures charged that are unusual for the diagnosis
7. Administrative fees that are excessive

Return ONLY a valid JSON object with this exact structure:
{
  "hospitalName": "Hospital or clinic name if visible, otherwise Unknown",
  "summary": "A concise overall assessment of the bill in 2-3 sentences",
  "totalAmount": 1234.56,
  "overallVerdict": "clean",
  "recommendation": "Specific advice on what the patient should do next",
  "issues": [
    {
      "itemName": "Name of the charged item or service",
      "issueType": "overcharged",
      "description": "Detailed explanation of why this is an issue and what the expected amount should be",
      "severity": "high"
    }
  ]
}

Rules:
- overallVerdict must be exactly one of: "clean", "suspicious", "problematic"
- issueType must be exactly one of: "overcharged", "double_charged", "unnecessary", "unusual_price", "missing_info"
- severity must be exactly one of: "high", "medium", "low"
- high severity = clear evidence of overcharging or double billing
- medium severity = suspicious pricing or unnecessary items
- low severity = minor concerns or unclear descriptions
- If the bill looks completely legitimate with no concerns, return empty issues array and verdict "clean"
- totalAmount should be null if not clearly visible in the image
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '';

      String jsonText = text.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      final json =
          BillAnalysis.fromJson(Map<String, dynamic>.from(_parseJson(jsonText)));
      return json;
    } catch (e) {
      throw Exception('Failed to analyze bill: $e');
    }
  }

  /// Start a chat session for a specific medicine
  Future<ChatSession> createMedicineChat(Medicine medicine) async {
    // Initialize model with tools if needed, or just use the default one
    // Note: To use tools, we might need to re-initialize the model or use a specific one
    final chatModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _cachedKey ?? _fallbackKey,
    );

    final chat = chatModel.startChat();
    
    final contextPrompt = '''
You are a helpful and knowledgeable medical assistant. I am asking questions about a medicine with the following details:
Name: ${medicine.name}
Chemical Contents: ${medicine.chemicalContents.join(', ')}
General Use: ${medicine.generalUse}
Harmful Contents: ${medicine.harmfulContents.map((h) => h.substance).join(', ')}
Age Precautions: ${medicine.agePrecautions.join(', ')}

Please engage in a natural, informative discussion about this medicine.
IMPORTANT INSTRUCTIONS:
1. DO NOT use phrases like "based on the information provided", "according to the text", or "as mentioned above".
2. Use your general medical knowledge to provide comprehensive and up-to-date answers.
3. If the user asks about something not in the initial details, SEARCH for it.
4. Be conversational and helpful, like a real doctor or pharmacist.
''';
    
    // Send initial context
    await chat.sendMessage(Content.text(contextPrompt));
    return chat;
  }
}

class PrescriptionMedicine {
  final String medicineName;
  final String timing; // 'morning', 'afternoon', 'night'
  final bool beforeEating;

  PrescriptionMedicine({
    required this.medicineName,
    required this.timing,
    required this.beforeEating,
  });

  factory PrescriptionMedicine.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicine(
      medicineName: json['medicineName'] as String? ?? 'Unknown',
      timing: json['timing'] as String? ?? 'morning',
      beforeEating: json['beforeEating'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'timing': timing,
      'beforeEating': beforeEating,
    };
  }
}
