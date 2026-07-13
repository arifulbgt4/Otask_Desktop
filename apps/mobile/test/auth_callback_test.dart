import 'package:flutter_test/flutter_test.dart';
import 'package:otask_mobile/auth_callback.dart';

void main() {
  test('accepts a PKCE code callback with state', () {
    final result = parseAuthCallback(
      Uri.parse('otask://auth/callback?code=abc&state=xyz'),
    );

    expect(result.kind, AuthCallbackKind.success);
    expect(result.code, 'abc');
    expect(result.state, 'xyz');
  });

  test('rejects implicit-flow fragments and missing state', () {
    expect(
      parseAuthCallback(
        Uri.parse('otask://auth/callback#access_token=secret'),
      ).error,
      'implicit_flow_not_allowed',
    );
    expect(
      parseAuthCallback(Uri.parse('otask://auth/callback?code=abc')).error,
      'missing_code_or_state',
    );
  });

  test('accepts only exact redirect contracts', () {
    expect(isAllowedAuthRedirect(Uri.parse('otask://auth/callback')), isTrue);
    expect(
      isAllowedAuthRedirect(Uri.parse('https://evil.example/auth/callback')),
      isFalse,
    );
  });
}
