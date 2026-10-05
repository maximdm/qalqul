import 'package:local_auth/local_auth.dart';

/// Result of a platform authentication attempt.
enum AuthOutcome {
  /// User authenticated successfully.
  success,

  /// User dismissed or failed the prompt (no match, cancelled, locked out…).
  failed,

  /// The device has no credentials or biometrics enrolled, so the prompt can
  /// never succeed — the caller should stop asking and let the user through.
  unavailable,
}

/// Thin wrapper over `local_auth` so the rest of the app never touches the
/// plugin API directly.
class AppLockService {
  AppLockService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device can satisfy an authentication prompt at all.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Whether at least one biometric (fingerprint/face) is enrolled.
  Future<bool> hasBiometrics() async {
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user. [reason] is shown by the OS prompt and should be
  /// localised. [biometricOnly] rejects the device-passcode fallback.
  Future<AuthOutcome> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
      return ok ? AuthOutcome.success : AuthOutcome.failed;
    } on LocalAuthException catch (e) {
      // No credentials at all: retrying will never help.
      if (e.code == LocalAuthExceptionCode.noCredentialsSet ||
          e.code == LocalAuthExceptionCode.noBiometricHardware ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
        return AuthOutcome.unavailable;
      }
      // Cancelled, timed out, lockout, device error → just a failed attempt.
      return AuthOutcome.failed;
    } catch (_) {
      return AuthOutcome.failed;
    }
  }
}