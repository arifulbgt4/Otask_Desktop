enum AuthCallbackKind { success, error }

class AuthCallbackResult {
  const AuthCallbackResult.success(this.code, this.state)
      : kind = AuthCallbackKind.success,
        error = null;

  const AuthCallbackResult.error(this.error)
      : kind = AuthCallbackKind.error,
        code = null,
        state = null;

  final AuthCallbackKind kind;
  final String? code;
  final String? state;
  final String? error;
}

const allowedAuthRedirects = <String>{
  'http://localhost:3000/auth/callback',
  'http://127.0.0.1:3000/auth/callback',
  'otask://auth/callback',
};

bool isAllowedAuthRedirect(Uri uri) {
  return allowedAuthRedirects.contains(uri.toString());
}

AuthCallbackResult parseAuthCallback(Uri uri) {
  if (uri.fragment.isNotEmpty) {
    return const AuthCallbackResult.error('implicit_flow_not_allowed');
  }

  final error = uri.queryParameters['error'];
  if (error != null && error.isNotEmpty) {
    return AuthCallbackResult.error(error);
  }

  final code = uri.queryParameters['code'];
  final state = uri.queryParameters['state'];
  if (code == null || code.isEmpty || state == null || state.isEmpty) {
    return const AuthCallbackResult.error('missing_code_or_state');
  }

  return AuthCallbackResult.success(code, state);
}
