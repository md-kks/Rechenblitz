import 'dart:convert';

import '../learning_subject.dart';

class SubjectAssignmentEnvelope {
  SubjectAssignmentEnvelope({
    required this.subject,
    required Map<String, dynamic> data,
  }) : data = Map<String, dynamic>.unmodifiable(data);

  static const prefix = 'LB1:';

  final LearningSubject subject;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'v': 1,
    'subject': subject.storageKey,
    'data': data,
  };

  String get assignmentId {
    final bytes = utf8.encode(jsonEncode(toJson()));
    var hash = 2166136261;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 16777619) & 4294967295;
    }
    return hash.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  String toPayload() {
    final raw = utf8.encode(jsonEncode(toJson()));
    final encoded = base64Url.encode(raw).replaceAll('=', '');
    return '$prefix$encoded';
  }

  static SubjectAssignmentEnvelope? tryParse(String payload) {
    final clean = payload.trim();
    if (!clean.startsWith(prefix)) return null;
    try {
      var body = clean.substring(prefix.length);
      while (body.length % 4 != 0) {
        body += '=';
      }
      final decoded =
          jsonDecode(utf8.decode(base64Url.decode(body)))
              as Map<String, dynamic>;
      if (decoded['v'] != 1) return null;
      final rawSubject = decoded['subject'] as String?;
      LearningSubject? subject;
      for (final candidate in LearningSubject.values) {
        if (candidate.storageKey == rawSubject) {
          subject = candidate;
          break;
        }
      }
      if (subject == null) return null;

      final rawData = decoded['data'];
      if (rawData is! Map<String, dynamic>) return null;
      return SubjectAssignmentEnvelope(subject: subject, data: rawData);
    } catch (_) {
      return null;
    }
  }
}
