import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medicine_card.dart';
import 'chat_screen.dart';

class MedicineResultScreen extends StatefulWidget {
  final Medicine medicine;

  const MedicineResultScreen({
    Key? key,
    required this.medicine,
  }) : super(key: key);

  @override
  State<MedicineResultScreen> createState() => _MedicineResultScreenState();
}

class _MedicineResultScreenState extends State<MedicineResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWarnings();
    });
  }

  void _showWarnings() {
    // Show expiry warning first
    if (widget.medicine.isExpired) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_rounded, color: Colors.red, size: 48),
          title: const Text('Medicine Expired!'),
          content: Text(
            'This medicine expired in ${widget.medicine.expiryDate}. '
            'Using expired medicine can be ineffective or potentially harmful. '
            'Please dispose of it safely and consult a pharmacist for a replacement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('I Understand'),
            ),
          ],
        ),
      ).then((_) {
        // After expiry dialog, show interaction warning if any
        _showInteractionWarning();
      });
    } else {
      _showInteractionWarning();
    }
  }

  void _showInteractionWarning() {
    if (widget.medicine.interactionWarning != null &&
        widget.medicine.interactionWarning!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.medication_rounded,
              color: Colors.orange, size: 48),
          title: const Text('Drug Interaction Warning'),
          content: SingleChildScrollView(
            child: Text(widget.medicine.interactionWarning!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ReportService().shareMedicineReport(widget.medicine);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: MedicineCard(medicine: widget.medicine),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(medicine: widget.medicine),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Ask Follow-up'),
      ),
    );
  }
}
