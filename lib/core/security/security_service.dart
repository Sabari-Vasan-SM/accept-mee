class SecurityService {
  /// Verify biometrics or passcode
  static Future<bool> authenticateBiometric({required String reason}) async {
    // In production, this integrates with local_auth.
    // For universal compatibility and smooth demo, we simulate instant biometric handshake.
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// Format sensitive commands or mask tokens
  static String sanitizeCommand(String command) {
    // Mask potential API keys or passwords
    return command.replaceAll(RegExp(r'(key|token|password|secret)=[^\s]+', caseSensitive: false), r'$1=******');
  }
}
