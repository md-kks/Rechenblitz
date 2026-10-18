import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  ErrorPattern? classify(TrainingMode mode, String key) => ErrorClassifier.classify(
        mode: mode, taskKey: key, expected: 0, actual: 1,
      );

  group('Geometriediagnose folgt der beobachtbaren Teilanforderung', () {
    test('Geraden, Winkel, Figuren und Kreisbegriffe bleiben getrennt', () {
      expect(classify(TrainingMode.geometryRelations,
          'geomrel:lines:parallel:context0:fourth'), ErrorPattern.lineRelation);
      expect(classify(TrainingMode.geometryRelations,
          'geomrel:angle:smaller:reference:paper:fourth'), ErrorPattern.angleClassification);
      expect(classify(TrainingMode.geometryRelations,
          'geomrel:figure:2:context1:fourth'), ErrorPattern.figureClassification);
      expect(classify(TrainingMode.geometryRelations,
          'geomrel:circle:diameter:context2:fourth'), ErrorPattern.circleParts);
    });

    test('Körpereigenschaften und Würfelnetz-Falten bleiben getrennt', () {
      expect(classify(TrainingMode.geometryBodies, 'body:Würfel:Kanten'),
          ErrorPattern.bodyProperties);
      expect(classify(TrainingMode.geometryBodies, 'body:cube-net:faces'),
          ErrorPattern.cubeNetFoldability);
      expect(classify(TrainingMode.geometryBodies,
          'body:cube-net:fold:yes:local:edge:0-0_1-0'), ErrorPattern.cubeNetFoldability);
    });

    test('unbekannte neue Keys bleiben konservativ allgemein', () {
      expect(classify(TrainingMode.geometryRelations, 'geomrel:future:new'),
          ErrorPattern.geometryProperty);
      expect(classify(TrainingMode.geometryBodies, 'future:body:new'),
          ErrorPattern.spatialReasoning);
    });
  });
}
