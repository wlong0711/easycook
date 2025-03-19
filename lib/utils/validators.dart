class Validators {
  // Validate Email Format
  static String? validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (email.isEmpty) {
      return "Email cannot be empty";
    } else if (!emailRegex.hasMatch(email)) {
      return "Enter a valid email address";
    }
    return null;  // Valid email
  }

  // Validate Password Length
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Password cannot be empty";
    } else if (password.length < 8) {
      return "Password must be at least 8 characters";
    }
    return null;  // Valid password
  }

  static String? validatePhoneNumber(String value) {
    final phoneRegex = RegExp(r'^\+?\d{10,15}$');  // Supports +country codes
    if (value.isEmpty) {
      return "Phone number is required";
    } else if (!phoneRegex.hasMatch(value)) {
      return "Enter a valid phone number";
    }
    return null;
  }
}
