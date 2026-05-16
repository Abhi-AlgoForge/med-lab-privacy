import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/medication_reminder.dart';
import '../models/medicine.dart';
import '../models/dose_record.dart';

class StorageService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyReminders = 'medication_reminders';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyMedicineHistory = 'medicine_history';
  static const String _keyPrescriptionHistory = 'prescription_history';
  static const String _keyDoseRecords = 'dose_records';
  static const String _keyFeatureTourComplete = 'feature_tour_complete';
  static const String _keyDailyScanCount = 'daily_scan_count';
  static const String _keyDailyScanDate = 'daily_scan_date';
  static const String _keyIsProUser = 'is_pro_user';

  static const int freeDailyLimit = 3;

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(profile.toJson());
    await prefs.setString(_keyUserProfile, jsonString);
  }

  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyUserProfile);
    if (jsonString == null) return null;
    
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserProfile.fromJson(json);
  }

  Future<void> saveReminders(List<MedicationReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_keyReminders, jsonString);
  }

  Future<List<MedicationReminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyReminders);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => MedicationReminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addReminder(MedicationReminder reminder) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }

  Future<void> updateReminder(MedicationReminder updatedReminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      reminders[index] = updatedReminder;
      await saveReminders(reminders);
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == reminderId);
    await saveReminders(reminders);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ============================================================
  // MEDICINE HISTORY
  // ============================================================

  Future<void> addMedicineToHistory(Medicine medicine) async {
    final history = await getMedicineHistory();
    history.insert(0, medicine);
    // Cap at 100 items
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history.map((m) => m.toJson()).toList());
    await prefs.setString(_keyMedicineHistory, jsonString);
  }

  Future<List<Medicine>> getMedicineHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyMedicineHistory);
    if (jsonString == null) return [];
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => Medicine.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteMedicineFromHistory(String id) async {
    final history = await getMedicineHistory();
    history.removeWhere((m) => m.id == id);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history.map((m) => m.toJson()).toList());
    await prefs.setString(_keyMedicineHistory, jsonString);
  }

  Future<void> clearMedicineHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMedicineHistory);
  }

  // ============================================================
  // PRESCRIPTION HISTORY
  // ============================================================

  Future<void> addPrescriptionScan(Map<String, dynamic> scan) async {
    final history = await getPrescriptionHistory();
    history.insert(0, scan);
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history);
    await prefs.setString(_keyPrescriptionHistory, jsonString);
  }

  Future<List<Map<String, dynamic>>> getPrescriptionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPrescriptionHistory);
    if (jsonString == null) return [];
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> deletePrescriptionScan(String scanId) async {
    final history = await getPrescriptionHistory();
    history.removeWhere((s) => s['scanId'] == scanId);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history);
    await prefs.setString(_keyPrescriptionHistory, jsonString);
  }

  Future<void> clearPrescriptionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrescriptionHistory);
  }

  // ============================================================
  // DOSE RECORDS
  // ============================================================

  Future<void> recordDose(DoseRecord record) async {
    final records = await getDoseRecords();
    records.add(record);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_keyDoseRecords, jsonString);
  }

  Future<List<DoseRecord>> getDoseRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyDoseRecords);
    if (jsonString == null) return [];
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => DoseRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoseRecord>> getDoseRecordsForDate(String date) async {
    final records = await getDoseRecords();
    return records.where((r) => r.scheduledDate == date).toList();
  }

  // ============================================================
  // FEATURE TOUR
  // ============================================================

  Future<bool> isFeatureTourComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFeatureTourComplete) ?? false;
  }

  Future<void> setFeatureTourComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFeatureTourComplete, true);
  }

  // ============================================================
  // PRO / SCAN LIMITS
  // ============================================================

  Future<bool> isProUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsProUser) ?? false;
  }

  Future<void> setProUser(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsProUser, value);
  }

  Future<int> getDailyScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDailyScanDate) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Reset count if it's a new day
    if (savedDate != today) {
      await prefs.setInt(_keyDailyScanCount, 0);
      await prefs.setString(_keyDailyScanDate, today);
      return 0;
    }
    return prefs.getInt(_keyDailyScanCount) ?? 0;
  }

  Future<int> getRemainingScans() async {
    final isPro = await isProUser();
    if (isPro) return -1; // Unlimited
    final used = await getDailyScanCount();
    return (freeDailyLimit - used).clamp(0, freeDailyLimit);
  }

  Future<bool> canScan() async {
    final isPro = await isProUser();
    if (isPro) return true;
    final used = await getDailyScanCount();
    return used < freeDailyLimit;
  }

  Future<void> incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_keyDailyScanDate, today);
    final current = prefs.getInt(_keyDailyScanCount) ?? 0;
    await prefs.setInt(_keyDailyScanCount, current + 1);
  }
}
