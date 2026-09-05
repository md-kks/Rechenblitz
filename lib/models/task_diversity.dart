import 'dart:math';

import 'math_fact.dart';
import 'training.dart';

class TaskDiversity {
  const TaskDiversity._();

  static String familyForKey(String key) {
    final parts = key.split(':');
    if (parts.isEmpty) return key;
    if (parts.length == 1) return parts.first;

    final head = parts[0];
    final second = parts[1];

    if (head == 'story' || head == 'money' || head == 'measure') {
      if (head == 'story' &&
          second == 'transfer' &&
          parts.length > 6 &&
          parts[2] == 'skill') {
        return 'story:transfer:${parts[3]}:${parts[5]}';
      }
      if (parts.length > 2 && int.tryParse(parts[2]) == null) {
        return '$head:$second:${parts[2]}';
      }
      return '$head:$second';
    }

    if (head == 'geometry' ||
        head == 'large' ||
        head == 'law' ||
        head == 'roman' ||
        head == 'fraction' ||
        head == 'data' ||
        head == 'prob' ||
        head == 'body' ||
        head == 'plan' ||
        head == 'duration' ||
        head == 'mental' ||
        head == 'written' ||
        head == 'remediation') {
      return '$head:$second';
    }

    if (head == 'sequence' ||
        head == 'gap' ||
        head == 'family' ||
        head == 'rect' ||
        head == 'combo' ||
        head == 'proportion') {
      return '$head:$second';
    }

    return head;
  }

  static String factFamily(MathFact fact) {
    if (fact.operation == MathOperation.plus ||
        fact.operation == MathOperation.multiply) {
      final low = min(fact.a, fact.b);
      final high = max(fact.a, fact.b);
      return '${fact.operation.name}:$low:$high';
    }
    return '${fact.operation.name}:${fact.a}:${fact.b}';
  }

  static int recentExactWindow({
    required TrainingMode mode,
    required int maxValue,
  }) {
    if (maxValue <= 10) return 5;
    if (maxValue <= 20) return 8;
    if (mode == TrainingMode.multiply || mode == TrainingMode.divide) {
      return 10;
    }
    return 14;
  }

  static int recentFamilyWindow(TrainingMode mode) {
    if (mode == TrainingMode.wordProblems ||
        mode == TrainingMode.money ||
        mode == TrainingMode.measures ||
        mode == TrainingMode.geometry ||
        mode.isUpperPrimary) {
      return 3;
    }
    return 1;
  }
}

class TaskDiversityAudit {
  const TaskDiversityAudit({
    required this.total,
    required this.uniqueKeys,
    required this.uniqueFamilies,
    required this.immediateRepeats,
    required this.repeatWithinFive,
  });

  final int total;
  final int uniqueKeys;
  final int uniqueFamilies;
  final int immediateRepeats;
  final int repeatWithinFive;

  double get uniqueKeyShare => total == 0 ? 1 : uniqueKeys / total;
  double get uniqueFamilyShare => total == 0 ? 1 : uniqueFamilies / total;
  double get immediateRepeatShare =>
      total <= 1 ? 0 : immediateRepeats / (total - 1);
  double get repeatWithinFiveShare =>
      total <= 1 ? 0 : repeatWithinFive / (total - 1);

  static TaskDiversityAudit analyze(List<String> keys) {
    var immediate = 0;
    var withinFive = 0;
    for (var i = 0; i < keys.length; i++) {
      if (i > 0 && keys[i] == keys[i - 1]) immediate += 1;
      final start = max(0, i - 5);
      if (keys.sublist(start, i).contains(keys[i])) withinFive += 1;
    }
    return TaskDiversityAudit(
      total: keys.length,
      uniqueKeys: keys.toSet().length,
      uniqueFamilies: keys.map(TaskDiversity.familyForKey).toSet().length,
      immediateRepeats: immediate,
      repeatWithinFive: withinFive,
    );
  }
}
