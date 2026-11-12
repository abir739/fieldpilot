import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/domain/asset_code.dart';

void main() {
  test('cleans spaces and uses upper case', () {
    expect(parseAssetCode(' pump-42 '), 'PUMP-42');
  });

  test('rejects empty, missing and strange text', () {
    expect(parseAssetCode(''), isNull);
    expect(parseAssetCode(null), isNull);
    expect(parseAssetCode('https://evil.com/?x=1'), isNull);
  });
}
