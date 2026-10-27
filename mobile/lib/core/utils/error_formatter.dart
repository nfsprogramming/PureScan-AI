class ErrorFormatter {
  static String getReadableMessage(Object error) {
    final str = error.toString();
    
    // Google Sign In
    if (str.contains('canceled') || str.contains('cancelled') || str.contains('sign_in_canceled')) {
      return 'Sign in was cancelled.';
    }
    
    // Network / Connectivity
    if (str.contains('network_error') || str.contains('SocketException') || str.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    // Common Auth Errors
    if (str.contains('invalid-credential') || str.contains('wrong-password') || str.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    
    // Supabase Auth Exceptions
    if (str.startsWith('AuthException(')) {
      final match = RegExp(r'message: (.*?)(?:,|$)').firstMatch(str);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }
    
    // Cleanup generic Exception prefixes
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    
    // Fallback cleanup
    return str.replaceAll('Exception: ', '')
              .replaceAll('AuthException(message: ', '')
              .replaceAll(RegExp(r', statusCode: \d+\)'), '')
              .trim();
  }
}
