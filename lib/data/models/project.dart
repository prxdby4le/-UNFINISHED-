// lib/data/models/project.dart
class Project {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  
  Project({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });
  
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cover_image_url': coverImageUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_archived': isArchived,
    };
  }
}
