import 'package:flutter/material.dart';

import 'app/learning_app_edition.dart';
import 'app/learning_blitz_app.dart';
import 'services/app_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(WortblitzBootstrap(controller: AppController()));
}

class WortblitzBootstrap extends LearningBlitzBootstrap {
  const WortblitzBootstrap({
    super.key,
    required super.controller,
    super.loadController,
  }) : super(edition: LearningAppEdition.wortblitz);
}

class WortblitzApp extends LearningBlitzApp {
  const WortblitzApp({super.key, required super.controller})
    : super(edition: LearningAppEdition.wortblitz);
}
