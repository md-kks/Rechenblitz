import 'package:flutter/material.dart';

import '../core/learning_subject.dart';

enum LearningAppEdition { rechenblitz, wortblitz }

extension LearningAppEditionX on LearningAppEdition {
  String get title => switch (this) {
    LearningAppEdition.rechenblitz => 'Rechenblitz',
    LearningAppEdition.wortblitz => 'Wortblitz',
  };

  LearningSubject get subject => switch (this) {
    LearningAppEdition.rechenblitz => LearningSubject.mathematics,
    LearningAppEdition.wortblitz => LearningSubject.german,
  };

  IconData get icon => switch (this) {
    LearningAppEdition.rechenblitz => Icons.flash_on_rounded,
    LearningAppEdition.wortblitz => Icons.auto_stories_rounded,
  };

  String get startupFailureText => '$title konnte nicht starten.';

  String get startupProgressText => '$title startet …';
}
