/// Modèles des réponses de l'API Xtream Codes (`player_api.php`).
///
/// Les serveurs renvoient indifféremment des nombres ou des chaînes : tout est lu de façon tolérante.
library;

String? _string(Object? value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty || s == 'null') ? null : s;
}

class XtreamUserInfo {
  const XtreamUserInfo({required this.authenticated, this.status, this.expiresAt, this.maxConnections});

  factory XtreamUserInfo.fromJson(Map<String, Object?> json) {
    final expiry = int.tryParse(_string(json['exp_date']) ?? '');
    return XtreamUserInfo(
      authenticated: _string(json['auth']) == '1',
      status: _string(json['status']),
      expiresAt: expiry == null ? null : DateTime.fromMillisecondsSinceEpoch(expiry * 1000),
      maxConnections: int.tryParse(_string(json['max_connections']) ?? ''),
    );
  }

  final bool authenticated;
  final String? status;
  final DateTime? expiresAt;
  final int? maxConnections;

  bool get isActive => status == null || status!.toLowerCase() == 'active';
}

class XtreamCategory {
  const XtreamCategory({required this.id, required this.name});

  factory XtreamCategory.fromJson(Map<String, Object?> json) =>
      XtreamCategory(id: _string(json['category_id']) ?? '', name: _string(json['category_name']) ?? 'Sans nom');

  final String id;
  final String name;
}

class XtreamLiveStream {
  const XtreamLiveStream({required this.streamId, required this.name, this.icon, this.categoryId, this.number});

  factory XtreamLiveStream.fromJson(Map<String, Object?> json) => XtreamLiveStream(
    streamId: _string(json['stream_id']) ?? '',
    name: _string(json['name']) ?? 'Sans nom',
    icon: _string(json['stream_icon']),
    categoryId: _string(json['category_id']),
    number: int.tryParse(_string(json['num']) ?? ''),
  );

  final String streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final int? number;
}
