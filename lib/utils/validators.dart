
class Validators {
  // Validates student registration number format (U05BB22S0000)
  static String? validateRegistrationNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Registration number is required';
    }
    
    // Check registration number format using regex
    // Format: U followed by 2 digits, 2 letters, 2 digits, S, and 4 digits
    RegExp regExp = RegExp(r'^U\d{2}[A-Z]{2}\d{2}S\d{4}$');
    
    if (!regExp.hasMatch(value)) {
      return 'Registration number must be in format: U##XX##S####';
    }
    
    return null;
  }
  
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }
} 