class Validators {
  // Email validation
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email.trim());
  }

  // Indian phone number
  static bool isValidIndianPhone(String phone) {
    return RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(phone.trim());
  }

  // Name validation
  static bool isValidName(String name) {
    return RegExp(r'^[a-zA-Z\s]{2,50}$').hasMatch(name.trim());
  }

  // Indian pincode
  static bool isValidIndianPincode(String pincode) {
    return RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode.trim());
  }

  // DOB validation
  static bool isValidDOB(String dob) {
    try {
      DateTime? date;
      
      // Check for DD/MM/YYYY format (common in India)
      if (dob.contains('/')) {
        final parts = dob.trim().split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          date = DateTime(year, month, day);
        }
      }

      // Fallback to ISO-8601
      date ??= DateTime.parse(dob.trim());

      final today = DateTime.now();

      if (date.isAfter(today)) return false;

      // Age calculation
      int age = today.year - date.year;
      if (today.month < date.month ||
          (today.month == date.month && today.day < date.day)) {
        age--;
      }

      // Enforce minimum age of 18 years for user registration
      return age >= 18 && age <= 120;
    } catch (_) {
      return false;
    }
  }

  // Andhra Pradesh pincode
  static bool isValidAndhraPradeshPincode(String pincode) {
    return RegExp(r'^(51|52|53)\d{4}$').hasMatch(pincode.trim());
  }

  // ✅ ADD THIS (FOR POLICE PASSWORD)
  static bool isValidPassword(String password) {
    // Minimum 8 chars, at least 1 letter and 1 number
    return RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$',
    ).hasMatch(password.trim());
  }
}
