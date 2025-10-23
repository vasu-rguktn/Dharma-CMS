
enum CaseStatus {
  newCase,
  underInvestigation,
  pendingTrial,
  resolved,
  closed,
}

extension CaseStatusExtension on CaseStatus {
  String get displayName {
    switch (this) {
      case CaseStatus.newCase:
        return "New";
      case CaseStatus.underInvestigation:
        return "Under Investigation";
      case CaseStatus.pendingTrial:
        return "Pending Trial";
      case CaseStatus.resolved:
        return "Resolved";
      case CaseStatus.closed:
        return "Closed";
    }
  }
  
  static CaseStatus fromString(String value) {
    switch (value) {
      case "New":
        return CaseStatus.newCase;
      case "Under Investigation":
        return CaseStatus.underInvestigation;
      case "Pending Trial":
        return CaseStatus.pendingTrial;
      case "Resolved":
        return CaseStatus.resolved;
      case "Closed":
        return CaseStatus.closed;
      default:
        return CaseStatus.newCase;
    }
  }
}
