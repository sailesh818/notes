import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId; // optional for migration
  final DateTime? reminderTime;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.reminderTime,
  });

  /// Convert Note to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'reminderTime': reminderTime?.toIso8601String(),
    };
  }

  /// Convert Note to Firestore map (use Timestamps)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
    };
  }

  /// Create a copy with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    DateTime? reminderTime,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  /// Create Note from local SQLite map
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      userId: map['userId'],
      reminderTime: map['reminderTime'] != null
          ? DateTime.tryParse(map['reminderTime'])
          : null,
    );
  }

  /// Create Note from Firestore document
  factory Note.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
      userId: data['userId'],
      reminderTime: data['reminderTime'] != null ? parseTimestamp(data['reminderTime']) : null,
    );
  }
}
