import 'dart:convert';
import 'dart:typed_data';

/// Represents a registered biometric person profile, inspired by kby-ai FaceRecognition.
class Person {
  final String id;
  final String name;
  final String employeeId;
  final Uint8List faceJpg;
  final List<double> templates;
  final DateTime enrolledAt;

  const Person({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.faceJpg,
    required this.templates,
    required this.enrolledAt,
  });

  factory Person.fromMap(Map<String, dynamic> data) {
    Uint8List jpgBytes;
    if (data['faceJpg'] is String) {
      jpgBytes = base64Decode(data['faceJpg'] as String);
    } else if (data['faceJpg'] is List) {
      jpgBytes = Uint8List.fromList(List<int>.from(data['faceJpg'] as List));
    } else {
      jpgBytes = Uint8List(0);
    }

    List<double> templateList = [];
    if (data['templates'] is List) {
      templateList = (data['templates'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    } else if (data['templates'] is String) {
      final decoded = jsonDecode(data['templates'] as String);
      if (decoded is List) {
        templateList = decoded.map((e) => (e as num).toDouble()).toList();
      }
    }

    return Person(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      employeeId: data['employeeId']?.toString() ?? '',
      faceJpg: jpgBytes,
      templates: templateList,
      enrolledAt: data['enrolledAt'] != null
          ? DateTime.tryParse(data['enrolledAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'employeeId': employeeId,
      'faceJpg': base64Encode(faceJpg),
      'templates': templates,
      'enrolledAt': enrolledAt.toIso8601String(),
    };
  }
}
