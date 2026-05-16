class BillAnalysis {
  final String hospitalName;
  final String summary;
  final double? totalAmount;
  final String overallVerdict; // 'clean' | 'suspicious' | 'problematic'
  final String recommendation;
  final List<BillIssue> issues;

  BillAnalysis({
    required this.hospitalName,
    required this.summary,
    this.totalAmount,
    required this.overallVerdict,
    required this.recommendation,
    required this.issues,
  });

  bool get hasIssues => issues.isNotEmpty;
  int get highSeverityCount =>
      issues.where((i) => i.severity == 'high').length;
  int get mediumSeverityCount =>
      issues.where((i) => i.severity == 'medium').length;

  factory BillAnalysis.fromJson(Map<String, dynamic> json) {
    final issuesList = json['issues'] as List<dynamic>? ?? [];
    return BillAnalysis(
      hospitalName: json['hospitalName'] as String? ?? 'Unknown Hospital',
      summary: json['summary'] as String? ?? 'Unable to analyze bill.',
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      overallVerdict: json['overallVerdict'] as String? ?? 'suspicious',
      recommendation: json['recommendation'] as String? ??
          'Please review the bill with a medical professional.',
      issues: issuesList
          .map((e) => BillIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hospitalName': hospitalName,
      'summary': summary,
      'totalAmount': totalAmount,
      'overallVerdict': overallVerdict,
      'recommendation': recommendation,
      'issues': issues.map((e) => e.toJson()).toList(),
    };
  }
}

class BillIssue {
  final String itemName;
  final String issueType; // 'overcharged' | 'double_charged' | 'unnecessary' | 'unusual_price' | 'missing_info'
  final String description;
  final String severity; // 'high' | 'medium' | 'low'

  BillIssue({
    required this.itemName,
    required this.issueType,
    required this.description,
    required this.severity,
  });

  factory BillIssue.fromJson(Map<String, dynamic> json) {
    return BillIssue(
      itemName: json['itemName'] as String? ?? 'Unknown item',
      issueType: json['issueType'] as String? ?? 'unusual_price',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'issueType': issueType,
      'description': description,
      'severity': severity,
    };
  }

  String get issueTypeLabel {
    switch (issueType) {
      case 'overcharged':
        return 'Overcharged';
      case 'double_charged':
        return 'Double Charged';
      case 'unnecessary':
        return 'Unnecessary';
      case 'unusual_price':
        return 'Unusual Price';
      case 'missing_info':
        return 'Missing Info';
      default:
        return 'Issue';
    }
  }
}
