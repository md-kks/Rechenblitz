import 'dart:convert';

import '../learning_subject.dart';

class SubjectResultEnvelope {
  SubjectResultEnvelope({
    required this.subject,
    required Map<String, dynamic> data,
  }) : data = Map<String, dynamic>.unmodifiable(data);

  static const prefix = 'LBR1:';

  final LearningSubject subject;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'v': 1,
    'subject': subject.storageKey,
    'data': data,
  };

  String toPayload() {
    final raw = utf8.encode(jsonEncode(toJson()));
    return '$prefix${base64Url.encode(raw).replaceAll('=', '')}';
  }

  static SubjectResultEnvelope? tryParse(String payload) {
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
      return SubjectResultEnvelope(subject: subject, data: rawData);
    } catch (_) {
      return null;
    }
  }
}
