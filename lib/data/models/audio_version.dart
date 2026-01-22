// lib/data/models/audio_version.dart
class AudioVersion {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final String fileUrl;
  final int? fileSize;
  final int? durationSeconds;
  final String? format;
  final String? uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isMaster;
  
  AudioVersion({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.fileUrl,
    this.fileSize,
    this.durationSeconds,
    this.format,
    this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
    this.isMaster = false,
  });
  
  factory AudioVersion.fromJson(Map<String, dynamic> json) {
    return AudioVersion(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      fileSize: json['file_size'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
      format: json['format'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isMaster: json['is_master'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'description': description,
      'file_url': fileUrl,
      'file_size': fileSize,
      'duration_seconds': durationSeconds,
      'format': format,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_master': isMaster,
    };
  }
  
  /// Formata duração para exibição (ex: "3:45")
  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Formata tamanho do arquivo (ex: "45.2 MB")
  String get formattedFileSize {
    if (fileSize == null) return '--';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
