import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanThinPoolExpansionTaskCatalog {
  const GermanThinPoolExpansionTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g2-family-mark-play',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „spiel-“.',
      prompt: 'Welche Wörter gehören wirklich zusammen?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['spielen', 'Spieler', 'Spielplatz'],
      choices: <String>[
        'spielen',
        'Spieler',
        'Spiegel',
        'Spielplatz',
        'spülen',
      ],
    ),
    GermanTask(
      id: 'g2-family-mark-drive',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „fahr-“.',
      prompt: 'Welche Wörter haben denselben Wortstamm?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['fahren', 'Fahrer', 'Fahrt'],
      choices: <String>['fahren', 'Fahrer', 'Farbe', 'Fahrt', 'Falle'],
    ),
    GermanTask(
      id: 'g2-family-mark-read',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „les-“.',
      prompt: 'Welche Wörter gehören zu „lesen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['lesen', 'Leser', 'Lesebuch'],
      choices: <String>['lesen', 'Leser', 'leise', 'Lesebuch', 'lösen'],
    ),
    GermanTask(
      id: 'g2-family-mark-paint',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „mal-“.',
      prompt: 'Welche Wörter gehören zu „malen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['malen', 'Maler', 'Malbild'],
      choices: <String>['malen', 'Maler', 'Mahlzeit', 'Malbild', 'mal'],
    ),
    GermanTask(
      id: 'g2-family-mark-build',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „bau-“.',
      prompt: 'Welche Wörter gehören zu „bauen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['bauen', 'Baustelle', 'Bauklotz'],
      choices: <String>['bauen', 'Baustelle', 'Baum', 'Bauklotz', 'Bauch'],
    ),
    GermanTask(
      id: 'g2-family-mark-learn',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „lern-“.',
      prompt: 'Welche Wörter gehören zu „lernen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['lernen', 'Lernheft', 'Lernzeit'],
      choices: <String>['lernen', 'Lernheft', 'Lärm', 'Lernzeit', 'leeren'],
    ),
    GermanTask(
      id: 'g2-family-mark-live',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „wohn-“.',
      prompt: 'Welche Wörter gehören zu „wohnen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['wohnen', 'Wohnung', 'Wohnhaus'],
      choices: <String>['wohnen', 'Wohnung', 'Wolle', 'Wohnhaus', 'Wonne'],
    ),
    GermanTask(
      id: 'g2-family-mark-write',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „schreib-“.',
      prompt: 'Welche Wörter gehören zu „schreiben“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['schreiben', 'Schreiber', 'Schreibheft'],
      choices: <String>[
        'schreiben',
        'Schreiber',
        'schreien',
        'Schreibheft',
        'Scheibe',
      ],
    ),
    GermanTask(
      id: 'g2-family-mark-sing',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „sing-“.',
      prompt: 'Welche Wörter gehören zu „singen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['singen', 'Sänger', 'Singstimme'],
      choices: <String>['singen', 'Sänger', 'sinken', 'Singstimme', 'Sieger'],
    ),
    GermanTask(
      id: 'g2-family-mark-laugh',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „lach-“.',
      prompt: 'Welche Wörter gehören zu „lachen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['lachen', 'Lacher', 'Lachgesicht'],
      choices: <String>['lachen', 'Lacher', 'machen', 'Lachgesicht', 'Dach'],
    ),
    GermanTask(
      id: 'g2-family-mark-swim',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „schwimm-“.',
      prompt: 'Welche Wörter gehören zu „schwimmen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['schwimmen', 'Schwimmer', 'Schwimmbad'],
      choices: <String>[
        'schwimmen',
        'Schwimmer',
        'Schwimmbad',
        'schlimm',
        'Schirm',
      ],
    ),
    GermanTask(
      id: 'g2-family-mark-buy',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere alle Wörter aus der Wortfamilie „kauf-“.',
      prompt: 'Welche Wörter gehören zu „kaufen“?',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['kaufen', 'Käufer', 'Einkauf'],
      choices: <String>['kaufen', 'Käufer', 'laufen', 'Einkauf', 'Haufen'],
    ),
    GermanTask(
      id: 'g4-inference-evidence-power-outage',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere alle Hinweise darauf, dass der Strom ausgefallen ist.',
      prompt:
          'Die Lampe bleibt dunkel. Der Kühlschrank ist plötzlich still. Auch im Nachbarhaus leuchten keine Fenster. Auf dem Tisch liegt ein Buch.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Die Lampe bleibt dunkel.',
        'Der Kühlschrank ist plötzlich still.',
        'Auch im Nachbarhaus leuchten keine Fenster.',
      ],
      choices: <String>[
        'Die Lampe bleibt dunkel.',
        'Der Kühlschrank ist plötzlich still.',
        'Auch im Nachbarhaus leuchten keine Fenster.',
        'Auf dem Tisch liegt ein Buch.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-bread',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere alle Hinweise darauf, dass jemand Brot backt.',
      prompt:
          'Auf der Arbeitsplatte liegt Mehl. In einer Schüssel geht Hefeteig auf. Der Backofen wird vorgeheizt. Neben der Spüle steht eine rote Tasse.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Auf der Arbeitsplatte liegt Mehl.',
        'In einer Schüssel geht Hefeteig auf.',
        'Der Backofen wird vorgeheizt.',
      ],
      choices: <String>[
        'Auf der Arbeitsplatte liegt Mehl.',
        'In einer Schüssel geht Hefeteig auf.',
        'Der Backofen wird vorgeheizt.',
        'Neben der Spüle steht eine rote Tasse.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-presentation',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Hinweise darauf, dass Lea eine Präsentation vorbereitet.',
      prompt:
          'Lea ordnet Karteikarten. Auf dem Laptop sind Folien geöffnet. Sie spricht ihren ersten Satz mehrfach laut. Ihr Mäppchen ist grün.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Lea ordnet Karteikarten.',
        'Auf dem Laptop sind Folien geöffnet.',
        'Sie spricht ihren ersten Satz mehrfach laut.',
      ],
      choices: <String>[
        'Lea ordnet Karteikarten.',
        'Auf dem Laptop sind Folien geöffnet.',
        'Sie spricht ihren ersten Satz mehrfach laut.',
        'Ihr Mäppchen ist grün.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-flat-tire',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere alle Hinweise auf einen platten Fahrradreifen.',
      prompt:
          'Der Hinterreifen liegt fast auf der Felge. Im Mantel steckt ein kleiner Nagel. Nach dem Aufpumpen entweicht die Luft sofort wieder. Der Helm hängt am Lenker.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Der Hinterreifen liegt fast auf der Felge.',
        'Im Mantel steckt ein kleiner Nagel.',
        'Nach dem Aufpumpen entweicht die Luft sofort wieder.',
      ],
      choices: <String>[
        'Der Hinterreifen liegt fast auf der Felge.',
        'Im Mantel steckt ein kleiner Nagel.',
        'Nach dem Aufpumpen entweicht die Luft sofort wieder.',
        'Der Helm hängt am Lenker.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-surprise-party',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Hinweise auf eine geplante Überraschungsfeier.',
      prompt:
          'Im Schrank sind Luftballons versteckt. Im Kühlschrank steht eine Torte. Mia flüstert: „Ben darf noch nichts merken.“ Das Küchenfenster ist geöffnet.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Im Schrank sind Luftballons versteckt.',
        'Im Kühlschrank steht eine Torte.',
        'Mia flüstert: „Ben darf noch nichts merken.“',
      ],
      choices: <String>[
        'Im Schrank sind Luftballons versteckt.',
        'Im Kühlschrank steht eine Torte.',
        'Mia flüstert: „Ben darf noch nichts merken.“',
        'Das Küchenfenster ist geöffnet.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-night-rain',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Hinweise darauf, dass es in der Nacht geregnet hat.',
      prompt:
          'Am Morgen stehen Pfützen auf dem Hof. Das Dach glänzt noch nass. Im Regenmesser ist Wasser. Jetzt scheint bereits die Sonne.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Am Morgen stehen Pfützen auf dem Hof.',
        'Das Dach glänzt noch nass.',
        'Im Regenmesser ist Wasser.',
      ],
      choices: <String>[
        'Am Morgen stehen Pfützen auf dem Hof.',
        'Das Dach glänzt noch nass.',
        'Im Regenmesser ist Wasser.',
        'Jetzt scheint bereits die Sonne.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-bus-gone',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Hinweise darauf, dass der Bus wahrscheinlich schon abgefahren ist.',
      prompt:
          'Die Haltestelle ist leer. Auf dem Fahrplan steht 8:05 Uhr. Leas Uhr zeigt 8:10 Uhr. Auf der Bank liegt eine Zeitung.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Die Haltestelle ist leer.',
        'Auf dem Fahrplan steht 8:05 Uhr.',
        'Leas Uhr zeigt 8:10 Uhr.',
      ],
      choices: <String>[
        'Die Haltestelle ist leer.',
        'Auf dem Fahrplan steht 8:05 Uhr.',
        'Leas Uhr zeigt 8:10 Uhr.',
        'Auf der Bank liegt eine Zeitung.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-camping',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Hinweise darauf, dass die Familie einen Campingausflug vorbereitet.',
      prompt:
          'Im Flur liegen ein zusammengerollter Schlafsack und ein Zelt. Papa prüft die Taschenlampe. Auf dem Tisch steht eine Einkaufsliste für Campinggas. Die Wohnzimmeruhr zeigt vier Uhr.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Im Flur liegen ein zusammengerollter Schlafsack und ein Zelt.',
        'Papa prüft die Taschenlampe.',
        'Auf dem Tisch steht eine Einkaufsliste für Campinggas.',
      ],
      choices: <String>[
        'Im Flur liegen ein zusammengerollter Schlafsack und ein Zelt.',
        'Papa prüft die Taschenlampe.',
        'Auf dem Tisch steht eine Einkaufsliste für Campinggas.',
        'Die Wohnzimmeruhr zeigt vier Uhr.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-library-closing',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Hinweise darauf, dass die Bücherei gleich schließt.',
      prompt:
          'Eine Mitarbeiterin stellt zurückgegebene Bücher in einen Wagen. Über Lautsprecher wird um die letzten Ausleihen gebeten. Im hinteren Leseraum werden bereits Lampen ausgeschaltet. Vor dem Fenster fährt ein rotes Auto vorbei.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Eine Mitarbeiterin stellt zurückgegebene Bücher in einen Wagen.',
        'Über Lautsprecher wird um die letzten Ausleihen gebeten.',
        'Im hinteren Leseraum werden bereits Lampen ausgeschaltet.',
      ],
      choices: <String>[
        'Eine Mitarbeiterin stellt zurückgegebene Bücher in einen Wagen.',
        'Über Lautsprecher wird um die letzten Ausleihen gebeten.',
        'Im hinteren Leseraum werden bereits Lampen ausgeschaltet.',
        'Vor dem Fenster fährt ein rotes Auto vorbei.',
      ],
    ),
    GermanTask(
      id: 'g4-inference-evidence-sports-day-indoor',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Hinweise darauf, dass der Sporttag wahrscheinlich nach drinnen verlegt wird.',
      prompt:
          'Auf dem Sportplatz stehen große Wasserlachen. Es regnet weiter stark. Die Lehrerin trägt Geräte in die Turnhalle. Auf einem Fensterbrett steht eine Pflanze.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Auf dem Sportplatz stehen große Wasserlachen.',
        'Es regnet weiter stark.',
        'Die Lehrerin trägt Geräte in die Turnhalle.',
      ],
      choices: <String>[
        'Auf dem Sportplatz stehen große Wasserlachen.',
        'Es regnet weiter stark.',
        'Die Lehrerin trägt Geräte in die Turnhalle.',
        'Auf einem Fensterbrett steht eine Pflanze.',
      ],
    ),
  ];
}
