import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Commercial/Advertisement model for the app
class Commercial {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String url;
  final String ctaText;
  final DateTime date;

  Commercial({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.url = '',
    this.ctaText = 'Learn More',
    required this.date,
  });

  /// Create a Commercial from a map (e.g., Firestore document)
  factory Commercial.fromMap(Map<String, dynamic> map, String docId) {
    return Commercial(
      id: docId,
      title: map['title'] ?? 'Advertisement',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      url: map['url'] ?? '',
      ctaText: map['ctaText'] ?? 'Learn More',
      date: map['date'] != null 
          ? (map['date'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  /// Convert to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'url': url,
      'ctaText': ctaText,
      'date': date,
    };
  }
} 