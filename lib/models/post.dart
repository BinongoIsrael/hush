import 'dart:convert';

class Post {
  final String id;
  final String userId;
  final String content;
  final bool isAnonymous;
  final List<String> tags;
  final int reactionCount;
  final String createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.isAnonymous,
    this.tags = const [],
    this.reactionCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'is_anonymous': isAnonymous ? 1 : 0,
      'tags': jsonEncode(tags),
      'reaction_count': reactionCount,
      'created_at': createdAt,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      content: map['content'] ?? '',
      isAnonymous: (map['is_anonymous'] ?? 0) == 1,
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      reactionCount: map['reaction_count']?.toInt() ?? 0,
      createdAt: map['created_at'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Post.fromJson(String source) => Post.fromMap(json.decode(source));
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final bool isAnonymous;
  final String? parentCommentId; // Added for threaded replies
  final String createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.isAnonymous,
    this.parentCommentId, // Nullable for top-level comments
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'is_anonymous': isAnonymous ? 1 : 0,
      'parent_comment_id': parentCommentId, // Added
      'created_at': createdAt,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      postId: map['post_id'],
      userId: map['user_id'],
      content: map['content'],
      isAnonymous: map['is_anonymous'] == 1,
      parentCommentId: map['parent_comment_id'], // Added
      createdAt: map['created_at'],
    );
  }
}