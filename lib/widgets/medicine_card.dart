import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../theme/app_theme.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;

  const MedicineCard({
    Key? key,
    required this.medicine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware text styles
    final headingColor = colorScheme.onSurface;
    final bodyColor = colorScheme.onSurfaceVariant;
    final mutedColor = colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine name
            Text(
              medicine.name,
              style: AppTheme.headingMedium.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),

            // Expiry date section
            if (medicine.expiryDate != null && medicine.expiryDate!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: medicine.isExpired
                      ? Colors.red.withOpacity(isDark ? 0.15 : 0.08)
                      : Colors.green.withOpacity(isDark ? 0.12 : 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: medicine.isExpired
                        ? Colors.red.withOpacity(isDark ? 0.5 : 1)
                        : Colors.green.withOpacity(isDark ? 0.4 : 1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      medicine.isExpired ? Icons.error_rounded : Icons.verified_rounded,
                      color: medicine.isExpired
                          ? (isDark ? Colors.red[300] : Colors.red[700])
                          : (isDark ? Colors.green[300] : Colors.green[700]),
                      size: 24,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.isExpired ? 'EXPIRED' : 'Valid Medicine',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: medicine.isExpired
                                  ? (isDark ? Colors.red[300] : Colors.red[700])
                                  : (isDark ? Colors.green[300] : Colors.green[700]),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            medicine.isExpired
                                ? 'Expired: ${medicine.expiryDate}'
                                : 'Valid until: ${medicine.expiryDate}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: bodyColor,
                              fontSize: 14,
                            ),
                          ),
                          if (medicine.manufactureDate != null &&
                              medicine.manufactureDate!.isNotEmpty)
                            Text(
                              'Manufactured: ${medicine.manufactureDate}',
                              style: AppTheme.bodyMedium.copyWith(
                                color: mutedColor,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ] else if (medicine.manufactureDate != null &&
                medicine.manufactureDate!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.factory_outlined, size: 16, color: mutedColor),
                  const SizedBox(width: AppTheme.spacingXSmall),
                  Text(
                    'Manufactured: ${medicine.manufactureDate}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: mutedColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Chemical contents
            if (medicine.chemicalContents.isNotEmpty) ...[
              Text(
                'Chemical Contents:',
                style: AppTheme.headingSmall.copyWith(
                  color: headingColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              ...medicine.chemicalContents.map((content) => Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacingMedium,
                      bottom: AppTheme.spacingXSmall,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          size: 8,
                          color: mutedColor,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: Text(
                            content,
                            style: AppTheme.bodyMedium.copyWith(
                              color: bodyColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // General Use
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(isDark ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                border: Border.all(
                  color: Colors.green.withOpacity(isDark ? 0.4 : 1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Use:',
                    style: AppTheme.headingSmall.copyWith(
                      color: isDark ? Colors.green[300] : Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    medicine.generalUse,
                    style: AppTheme.bodyMedium.copyWith(
                      color: bodyColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),

            // Harmful contents warning
            if (medicine.harmfulContents.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.cautionOrange.withOpacity(isDark ? 0.12 : 0.1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: AppTheme.cautionOrange.withOpacity(isDark ? 0.4 : 1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: isDark ? Colors.orange[300] : AppTheme.cautionOrange,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          'Harmful Content Warning',
                          style: AppTheme.bodyLarge.copyWith(
                            color: isDark ? Colors.orange[300] : AppTheme.cautionOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    ...medicine.harmfulContents.map((harmful) => Padding(
                          padding: const EdgeInsets.only(
                            top: AppTheme.spacingSmall,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (harmful.isSuspicious)
                                    Icon(
                                      Icons.error,
                                      color: isDark ? Colors.red[300] : AppTheme.warningRed,
                                      size: 16,
                                    ),
                                  if (harmful.isSuspicious)
                                    const SizedBox(width: AppTheme.spacingXSmall),
                                  Expanded(
                                    child: Text(
                                      harmful.substance,
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: harmful.isSuspicious
                                            ? (isDark ? Colors.red[300] : AppTheme.warningRed)
                                            : headingColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingXSmall),
                              Text(
                                harmful.description,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: bodyColor,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Age precautions
            if (medicine.agePrecautions.isNotEmpty) ...[
              Text(
                'Age-Specific Precautions:',
                style: AppTheme.headingSmall.copyWith(
                  color: headingColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              ...medicine.agePrecautions.map((precaution) => Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacingMedium,
                      bottom: AppTheme.spacingXSmall,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: Text(
                            precaution,
                            style: AppTheme.bodyMedium.copyWith(
                              color: bodyColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // Drug interaction warning
            if (medicine.interactionWarning != null &&
                medicine.interactionWarning!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: Colors.deepOrange.withOpacity(isDark ? 0.4 : 1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medication_rounded,
                          color: isDark
                              ? Colors.orange[300]
                              : Colors.deepOrange[700],
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          'Drug Interaction Warning',
                          style: AppTheme.bodyLarge.copyWith(
                            color: isDark
                                ? Colors.orange[300]
                                : Colors.deepOrange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      medicine.interactionWarning!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: bodyColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Bottom spacing so FAB doesn't cover content
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
