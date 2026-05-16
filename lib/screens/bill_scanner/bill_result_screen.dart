import 'package:flutter/material.dart';
import '../../models/bill_analysis.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';

class BillResultScreen extends StatelessWidget {
  final BillAnalysis billAnalysis;

  const BillResultScreen({Key? key, required this.billAnalysis})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ReportService().shareBillReport(billAnalysis);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VerdictCard(billAnalysis: billAnalysis),
            const SizedBox(height: AppTheme.spacingMedium),
            if (billAnalysis.hasIssues) ...[
              _SectionHeader(
                title: 'Issues Found',
                subtitle:
                    '${billAnalysis.issues.length} item${billAnalysis.issues.length == 1 ? '' : 's'} need your attention',
                color: colorScheme.error,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              ...billAnalysis.issues
                  .map((issue) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingSmall),
                        child: _IssueCard(issue: issue),
                      ))
                  .toList(),
              const SizedBox(height: AppTheme.spacingSmall),
            ],
            _RecommendationCard(billAnalysis: billAnalysis),
            const SizedBox(height: AppTheme.spacingLarge),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Verdict Card - hero section showing overall result
// ============================================================
class _VerdictCard extends StatelessWidget {
  final BillAnalysis billAnalysis;

  const _VerdictCard({required this.billAnalysis});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verdict = billAnalysis.overallVerdict;

    final Color verdictColor;
    final IconData verdictIcon;
    final String verdictLabel;

    switch (verdict) {
      case 'clean':
        verdictColor = AppTheme.successGreen;
        verdictIcon = Icons.verified_rounded;
        verdictLabel = 'Bill Looks Clean';
        break;
      case 'suspicious':
        verdictColor = AppTheme.cautionOrange;
        verdictIcon = Icons.warning_amber_rounded;
        verdictLabel = 'Suspicious Items Found';
        break;
      case 'problematic':
        verdictColor = colorScheme.error;
        verdictIcon = Icons.gpp_bad_rounded;
        verdictLabel = 'Significant Issues Detected';
        break;
      default:
        verdictColor = AppTheme.cautionOrange;
        verdictIcon = Icons.help_outline_rounded;
        verdictLabel = 'Review Required';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            verdictColor.withOpacity(isDark ? 0.2 : 0.12),
            verdictColor.withOpacity(isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
        border: Border.all(
          color: verdictColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: verdictColor.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Icon(verdictIcon, color: verdictColor, size: 28),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verdictLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: verdictColor,
                      ),
                    ),
                    if (billAnalysis.hospitalName != 'Unknown Hospital') ...[
                      const SizedBox(height: 2),
                      Text(
                        billAnalysis.hospitalName,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (billAnalysis.totalAmount != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${billAnalysis.totalAmount!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            billAnalysis.summary,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          if (billAnalysis.hasIssues) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                if (billAnalysis.highSeverityCount > 0)
                  _SeverityChip(
                    count: billAnalysis.highSeverityCount,
                    label: 'High',
                    color: colorScheme.error,
                  ),
                if (billAnalysis.highSeverityCount > 0 &&
                    billAnalysis.mediumSeverityCount > 0)
                  const SizedBox(width: AppTheme.spacingSmall),
                if (billAnalysis.mediumSeverityCount > 0)
                  _SeverityChip(
                    count: billAnalysis.mediumSeverityCount,
                    label: 'Medium',
                    color: AppTheme.cautionOrange,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SeverityChip(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// Section Header
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader(
      {required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// Individual Issue Card
// ============================================================
class _IssueCard extends StatelessWidget {
  final BillIssue issue;

  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color severityColor;
    final IconData issueIcon;

    switch (issue.severity) {
      case 'high':
        severityColor = colorScheme.error;
        break;
      case 'medium':
        severityColor = AppTheme.cautionOrange;
        break;
      default:
        severityColor = AppTheme.accentCyan;
    }

    switch (issue.issueType) {
      case 'overcharged':
        issueIcon = Icons.trending_up_rounded;
        break;
      case 'double_charged':
        issueIcon = Icons.content_copy_rounded;
        break;
      case 'unnecessary':
        issueIcon = Icons.block_rounded;
        break;
      case 'unusual_price':
        issueIcon = Icons.attach_money_rounded;
        break;
      case 'missing_info':
        issueIcon = Icons.info_outline_rounded;
        break;
      default:
        issueIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: severityColor.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Icon(issueIcon, color: severityColor, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.itemName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _TypeBadge(
                          label: issue.issueTypeLabel,
                          color: severityColor,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        _TypeBadge(
                          label:
                              '${issue.severity[0].toUpperCase()}${issue.severity.substring(1)} Risk',
                          color: severityColor,
                          outlined: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Container(
            height: 1,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            issue.description,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;

  const _TypeBadge(
      {required this.label, required this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: outlined ? Border.all(color: color.withOpacity(0.4)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// Recommendation Card
// ============================================================
class _RecommendationCard extends StatelessWidget {
  final BillAnalysis billAnalysis;

  const _RecommendationCard({required this.billAnalysis});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Icon(Icons.tips_and_updates_rounded,
                color: accentColor, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  billAnalysis.recommendation,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
