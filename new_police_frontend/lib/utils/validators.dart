class Validators {
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }

  static bool isValidIndianPhone(String phone) {
    return RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(phone.trim());
  }

  static bool isValidName(String name) {
    if (name.trim().length < 2) return false;
    if (RegExp(r'^\d+$').hasMatch(name.trim())) return false;
    return true;
  }

  static bool isValidIndianPincode(String pincode) {
    return RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode.trim());
  }

  static bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$').hasMatch(password.trim());
  }
}
