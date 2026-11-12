/// Turns raw QR text into a clean asset code, e.g. " pump-42 " -> "PUMP-42".
///
/// Returns null when the text cannot be an asset code.
String? parseAssetCode(String? raw) {
  final code = raw?.trim().toUpperCase() ?? '';
  final isValid = RegExp(r'^[A-Z0-9_-]{1,64}$').hasMatch(code);
  return isValid ? code : null;
}
