// lib/data/models/feedback.dart
class Feedback {
  final String id;
  final String audioVersionId;
  final String? authorId;
  final String? authorName;
  final String? authorEmail;
  final String? authorAvatarUrl;
  final String content;
  final int? timestampSeconds; // Timestamp no áudio (opcional)
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Feedback({
    required this.id,
    required this.audioVersionId,
    this.authorId,
    this.authorName,
    this.authorEmail,
    this.authorAvatarUrl,
    required this.content,
    this.timestampSeconds,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Feedback.fromJson(Map<String, dynamic> json) {
    // Extrair dados do perfil se vierem do join
    Map<String, dynamic>? profileData;
    if (json['profiles'] != null) {
      profileData = json['profiles'] is Map
          ? json['profiles'] as Map<String, dynamic>
          : null;
    }
    
    return Feedback(
      id: json['id'] as String,
      audioVersionId: json['audio_version_id'] as String,
      authorId: json['author_id'] as String?,
      authorName: profileData?['full_name'] as String? ?? 
                  json['author_name'] as String?,
      authorEmail: profileData?['email'] as String? ?? 
                   json['author_email'] as String?,
      authorAvatarUrl: profileData?['avatar_url'] as String? ?? 
                       json['author_avatar_url'] as String?,
      content: json['content'] as String,
      timestampSeconds: json['timestamp_seconds'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audio_version_id': audioVersionId,
      'author_id': authorId,
      'content': content,
      'timestamp_seconds': timestampSeconds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  /// Formata timestamp para exibição (ex: "1:23")
  String? get formattedTimestamp {
    if (timestampSeconds == null) return null;
    final minutes = timestampSeconds! ~/ 60;
    final seconds = timestampSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Verifica se o comentário é do usuário atual
  bool isOwnComment(String? currentUserId) {
    if (currentUserId == null || authorId == null) return false;
    return authorId == currentUserId;
  }
  
  /// Formata data relativa (ex: "há 2 horas")
  String get formattedRelativeDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'agora';
        }
        return 'há ${diff.inMinutes} ${diff.inMinutes == 1 ? 'minuto' : 'minutos'}';
      }
      return 'há ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
    } else if (diff.inDays < 7) {
      return 'há ${diff.inDays} ${diff.inDays == 1 ? 'dia' : 'dias'}';
    } else if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return 'há $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else {
      return 'há ${diff.inDays ~/ 30} ${(diff.inDays ~/ 30) == 1 ? 'mês' : 'meses'}';
    }
  }
}
