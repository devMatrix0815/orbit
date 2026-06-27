import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TextOverlay {
  final String text;
  final double x; // 0.0–1.0 fraction of container width
  final double y; // 0.0–1.0 fraction of container height
  final double fontSize;
  final int colorValue;

  const TextOverlay({
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 28.0,
    this.colorValue = 0xFFFFFFFF,
  });

  Color get color => Color(colorValue);

  TextOverlay copyWith({double? x, double? y}) => TextOverlay(
        text: text,
        x: x ?? this.x,
        y: y ?? this.y,
        fontSize: fontSize,
        colorValue: colorValue,
      );

  Map<String, dynamic> toMap() => {
        'text': text,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'colorValue': colorValue,
      };

  factory TextOverlay.fromMap(Map<String, dynamic> map) => TextOverlay(
        text: map['text'] as String? ?? '',
        x: (map['x'] as num?)?.toDouble() ?? 0.5,
        y: (map['y'] as num?)?.toDouble() ?? 0.5,
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 28.0,
        colorValue: map['colorValue'] as int? ?? 0xFFFFFFFF,
      );
}

class Story {
  final String id;
  final String circleId;
  final String creatorId;
  final String creatorName;
  final String? creatorImageBase64;
  final String imageBase64;
  final List<TextOverlay> textOverlays;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;

  const Story({
    required this.id,
    required this.circleId,
    required this.creatorId,
    required this.creatorName,
    this.creatorImageBase64,
    required this.imageBase64,
    required this.textOverlays,
    required this.createdAt,
    required this.expiresAt,
    required this.viewedBy,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      circleId: data['circleId'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? '',
      creatorImageBase64: data['creatorImageBase64'] as String?,
      imageBase64: data['imageBase64'] as String? ?? '',
      textOverlays: ((data['textOverlays'] as List<dynamic>?) ?? [])
          .map((e) => TextOverlay.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
    );
  }
}
