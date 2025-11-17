class Session {
  final String token;
  final String type; // 'user' | 'guest'
  final int userId;
  final int guestId;
  final DateTime? expiresAt;

  Session({
    required this.token,
    required this.type,
    required this.userId,
    required this.guestId,
    this.expiresAt,
  });
}
