import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// `drive.file`, which reaches the folder AlloMom created in the user's
  /// Drive and nothing else in it.
  static const String driveScope = 'https://www.googleapis.com/auth/drive.file';

  /// The OAuth client dedicated to Drive access.
  ///
  /// Passing it as `serverClientId` is what makes Google return a
  /// `serverAuthCode` alongside the sign-in. `/me/reports/drive/connect` trades
  /// that for a refresh token and thereafter reaches Drive on its own. Drop
  /// this and `serverAuthCode` comes back null, leaving the server nothing to
  /// exchange. The API must be configured with the matching secret
  /// (`DRIVE_GOOGLE_AUTH_SECRET`) for the same client.
  ///
  /// Deliberately not the client the app signs users in with: the secret behind
  /// it grants exactly one thing, and rotating or revoking it cannot disturb
  /// sign-in.
  static const String driveServerClientId =
      '478575784185-o5e09kbspfsaj1370n2p0p3ajp3nttrh.apps.googleusercontent.com';

  /// A second sign-in instance, for Drive only.
  ///
  /// Kept apart from [_googleSignIn] so linking a Drive never disturbs the
  /// account the user signed into AlloMom with, and so disconnecting Drive does
  /// not sign them out of the app.
  static final GoogleSignIn driveSignIn = GoogleSignIn(
    serverClientId: driveServerClientId,
    scopes: ['email', 'profile', driveScope],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      debugPrint('Google Sign In Error: $error');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Google Sign Out Error: $error');
    }
  }

  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Signs in with the Drive scope and returns the one-time code the server
  /// needs. Null when the user backs out, or when consent was refused.
  ///
  /// Goes through the full [GoogleSignIn.signIn] rather than a silent refresh:
  /// only a consented sign-in produces a code carrying offline access, which is
  /// the whole point of the exchange.
  static Future<String?> driveServerAuthCode() async {
    final account = await driveSignIn.signIn();
    if (account == null) return null;

    if (!driveSignIn.scopes.contains(driveScope)) {
      final granted = await driveSignIn.requestScopes([driveScope]);
      if (!granted) return null;
    }

    final code = account.serverAuthCode;
    return (code == null || code.isEmpty) ? null : code;
  }

  static Future<void> driveSignOut() async {
    try {
      await driveSignIn.signOut();
    } catch (error) {
      debugPrint('Google Drive Sign Out Error: $error');
    }
  }
}
