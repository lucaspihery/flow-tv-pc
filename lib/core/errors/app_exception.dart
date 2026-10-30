/// Erreur métier dont le message peut être affiché tel quel à l'utilisateur.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Serveur injoignable, délai dépassé, code HTTP inattendu…
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Identifiants refusés ou abonnement inactif.
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Réponse ou fichier dont le contenu n'est pas exploitable.
class ParseException extends AppException {
  const ParseException(super.message);
}
