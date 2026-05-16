import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medicine.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../medicine_scanner/medicine_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late TabController _tabController;

  List<Medicine> _medicineHistory = [];
  List<Map<String, dynamic>> _prescriptionHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final medicines = await _storage.getMedicineHistory();
    final prescriptions = await _storage.getPrescriptionHistory();
    if (mounted) {
      setState(() {
        _medicineHistory = medicines;
        _prescriptionHistory = prescriptions;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMedicine(String id) async {
    await _storage.deleteMedicineFromHistory(id);
    _loadHistory();
  }

  Future<void> _deletePrescription(String scanId) async {
    await _storage.deletePrescriptionScan(scanId);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    final tab = _tabController.index;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All'),
        content: Text(
          'Are you sure you want to delete all ${tab == 0 ? 'medicine scan' : 'prescription'} history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (tab == 0) {
      await _storage.clearMedicineHistory();
    } else {
      await _storage.clearPrescriptionHistory();
    }
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if ((_tabController.index == 0 && _medicineHistory.isNotEmpty) ||
              (_tabController.index == 1 && _prescriptionHistory.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Medicine Scans'),
            Tab(text: 'Prescriptions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMedicineList(colorScheme),
                _buildPrescriptionList(colorScheme),
              ],
            ),
    );
  }

  Widget _buildMedicineList(ColorScheme colorScheme) {
    if (_medicineHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_rounded,
                size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No medicine scans yet',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Scan a medicine to see it here',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: _medicineHistory.length,
      itemBuilder: (context, index) {
        final medicine = _medicineHistory[index];
        final dateStr = DateFormat('MMM d, yyyy - h:mm a').format(medicine.scannedAt);

        return Dismissible(
          key: Key(medicine.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          onDismissed: (_) => _deleteMedicine(medicine.id),
          child: Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicineResultScreen(medicine: medicine),
                  ),
                );
              },
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Icon(Icons.medication_rounded,
                    color: colorScheme.primary, size: 24),
              ),
              title: Text(
                medicine.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (medicine.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Expired',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionList(ColorScheme colorScheme) {
    if (_prescriptionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No prescription scans yet',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Scan a prescription to see it here',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: _prescriptionHistory.length,
      itemBuilder: (context, index) {
        final scan = _prescriptionHistory[index];
        final scanId = scan['scanId'] as String? ?? '';
        final scannedAt = scan['scannedAt'] as String? ?? '';
        final medicines = (scan['medicines'] as List<dynamic>?) ?? [];
        final dateStr = scannedAt.isNotEmpty
            ? DateFormat('MMM d, yyyy - h:mm a')
                .format(DateTime.tryParse(scannedAt) ?? DateTime.now())
            : 'Unknown date';
        final medicineNames =
            medicines.map((m) => (m as Map)['medicineName'] ?? '').join(', ');

        return Dismissible(
          key: Key(scanId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          onDismissed: (_) => _deletePrescription(scanId),
          child: Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: colorScheme.tertiary, size: 24),
              ),
              title: Text(
                '${medicines.length} medicine${medicines.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (medicineNames.isNotEmpty)
                    Text(
                      medicineNames,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: colorScheme.error),
                onPressed: () => _deletePrescription(scanId),
              ),
            ),
          ),
        );
      },
    );
  }
}
