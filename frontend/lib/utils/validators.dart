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
      final date = DateTime.parse(dob.trim());
      final today = DateTime.now();

      if (date.isAfter(today)) return false;

      int age = today.year - date.year;
      if (today.month < date.month ||
          (today.month == date.month && today.day < date.day)) {
        age--;
      }

      return age >= 18 && age <= 120;
    } catch (_) {
      return false;
    }
  }

  // ✅ ADD THIS INSIDE THE CLASS (NOT BELOW IT)
  static bool isValidAndhraPradeshPincode(String pincode) {
    return RegExp(r'^(51|52|53)\d{4}$').hasMatch(pincode.trim());
  }
}
