import 'package:flutter/material.dart';

import 'app/learning_app_edition.dart';
import 'app/learning_blitz_app.dart';
import 'services/app_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RechenblitzBootstrap(controller: AppController()));
}

class RechenblitzBootstrap extends LearningBlitzBootstrap {
  const RechenblitzBootstrap({
    super.key,
    required super.controller,
    super.loadController,
  }) : super(edition: LearningAppEdition.rechenblitz);
}

class RechenblitzApp extends LearningBlitzApp {
  const RechenblitzApp({super.key, required super.controller})
    : super(edition: LearningAppEdition.rechenblitz);
}
