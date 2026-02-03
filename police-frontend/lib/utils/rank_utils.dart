/// Utility functions for police rank classification
class RankUtils {
  /// List of high-level officer ranks (DGP to SP)
  static const List<String> highLevelRanks = [
    'DGP',
    'ADGP',
    'IGP',
    'DIG',
    'SP',
    'Director General of Police',
    'Additional Director General of Police',
    'Inspector General of Police',
    'Deputy Inspector General of Police', 
    'Superintendent of Police',
  ];

  /// List of low-level officer ranks (below SP)
  static const List<String> lowLevelRanks = [
    'ASP',
    'DSP',
    'CI',
    'SI',
    'ASI',
    'HC',
    'PC',
    'Additional Superintendent of Police',
    'Deputy Superintendent of Police',
    'Circle Inspector',
    'Sub-Inspector',
    'Assistant Sub-Inspector',
    'Head Constable',
    'Police Constable',
  ];

  /// Check if the given rank is a high-level officer (DGP to SP)
  /// Returns true for DGP, ADGP, IGP, DIG, SP
  static bool isHighLevelOfficer(String? rank) {
    if (rank == null || rank.isEmpty) return false;
    
    final normalizedRank = normalizeRank(rank);
    
    // Check for exact matches first for common abbreviations
    final abbreviations = ['DGP', 'ADGP', 'IGP', 'DIG', 'SP'];
    if (abbreviations.contains(normalizedRank)) return true;

    // Check for full titles
    final fullTitles = [
      'DIRECTOR GENERAL OF POLICE',
      'ADDITIONAL DIRECTOR GENERAL OF POLICE',
      'INSPECTOR GENERAL OF POLICE',
      'DEPUTY INSPECTOR GENERAL OF POLICE',
      'SUPERINTENDENT OF POLICE'
    ];
    
    if (fullTitles.contains(normalizedRank)) return true;

    // Additional check for SP to avoid matching ASP/DSP
    // Only return true if it's exactly "SP" or contains "SUPERINTENDENT OF POLICE" 
    // but DOES NOT contain "ADDITIONAL" or "DEPUTY" or "ASSISTANT"
    if (normalizedRank.contains('SUPERINTENDENT OF POLICE')) {
      if (normalizedRank.contains('ADDITIONAL') || 
          normalizedRank.contains('DEPUTY') || 
          normalizedRank.contains('ASSISTANT') ||
          normalizedRank.contains('ASP') ||
          normalizedRank.contains('DSP')) {
        return false;
      }
      return true;
    }

    return false;
  }

  /// Check if the given rank is a low-level officer (below SP)
  /// Returns true for ASP, DSP, CI, SI, ASI, HC, PC
  static bool isLowLevelOfficer(String? rank) {
    if (rank == null || rank.isEmpty) return false;
    return !isHighLevelOfficer(rank);
  }

  /// Check if the given rank is a range-level officer (IGP, DIG)
  static bool isRangeLevelOfficer(String? rank) {
    if (rank == null) return false;
    final normalized = normalizeRank(rank);
    return normalized.contains('INSPECTOR GENERAL') || 
           normalized.contains('IGP') || 
           normalized.contains('DEPUTY INSPECTOR GENERAL') || 
           normalized.contains('DIG');
  }

  /// Check if the given rank is a district-level officer (SP, ADL SP)
  static bool isDistrictLevelOfficer(String? rank) {
    if (rank == null) return false;
    final normalized = normalizeRank(rank);
    // Exact SP or SuperIntendent of Police
    if (normalized == 'SP' || normalized == 'SUPERINTENDENT OF POLICE') return true;
    if (normalized.contains('ADDITIONAL') && normalized.contains('SUPERINTENDENT OF POLICE')) return true;
    return false;
  }

  /// Check if the given rank is a station-level officer (Inspector and below)
  static bool isStationLevelOfficer(String? rank) {
    if (rank == null) return false;
    // Anything that isn't Range, District or State level is Station level
    return !isRangeLevelOfficer(rank) && 
           !isDistrictLevelOfficer(rank) && 
           !normalizeRank(rank).contains('DIRECTOR GENERAL');
  }

  /// Get display name for rank category
  static String getRankCategory(String? rank) {
    if (isHighLevelOfficer(rank)) {
      return 'High-Level Officer';
    } else if (isLowLevelOfficer(rank)) {
      return 'Low-Level Officer';
    } else {
      return 'Unknown Rank';
    }
  }

  /// Normalize rank string for comparison
  static String normalizeRank(String? rank) {
    if (rank == null || rank.isEmpty) return '';
    return rank.trim().toUpperCase();
  }
}
