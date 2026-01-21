// Add these helper methods to submit_offline_petition_screen.dart
// Place them BEFORE the @override Widget build() method (around line 217)

  String _getAssignmentLabel() {
    if (_assignmentData == null) return 'Not selected';
    final type = _assignmentData!['assignmentType'];
    if (type == 'range') {
      return 'Range: ${_assignmentData!['assignedToRange'] ?? 'Unknown'}';
    } else if (type == 'district') {
      return 'District: ${_assignmentData!['assignedToDistrict'] ?? 'Unknown'}';
    } else if (type == 'station') {
      return 'Station: ${_assignmentData!['assignedToStation'] ?? 'Unknown'}';
    }
    return 'Unknown assignment';
  }

  String _getAssignmentSubtitle() {
    if (_assignmentData == null) return '';
    final type = _assignmentData!['assignmentType'];
    if (type == 'range') {
      return 'Assigned to IG/DIG of this range';
    } else if (type == 'district') {
      return 'Assigned to SP of this district';
    } else if (type == 'station') {
      return 'Assigned to officers at this station';
    }
    return '';
  }
