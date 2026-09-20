import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanGradeFourListeningDiversityTaskCatalog {
  const GermanGradeFourListeningDiversityTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g4-listen-main-mark-plastic',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Mehrwegflaschen können Abfall vermeiden.',
        'Wiederholtes Benutzen spart neue Verpackungen.',
      ],
      choices: <String>[
        'Mehrwegflaschen können Abfall vermeiden.',
        'Wiederholtes Benutzen spart neue Verpackungen.',
        'Flaschen können durchsichtig sein.',
        'Viele Deckel sind rund.',
      ],
      spokenText:
          'Wer eine Mehrwegflasche immer wieder benutzt, braucht seltener neue Einwegverpackungen. Dadurch kann weniger Verpackungsabfall entstehen. Farbe und Form der Flasche spielen dafür keine wichtige Rolle.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-reading',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Regelmäßiges Lesen erweitert den Wortschatz.',
        'Lesen kann helfen, längere Texte besser zu verstehen.',
      ],
      choices: <String>[
        'Regelmäßiges Lesen erweitert den Wortschatz.',
        'Lesen kann helfen, längere Texte besser zu verstehen.',
        'Bücher haben Seitenzahlen.',
        'Manche Bücher sind gebunden.',
      ],
      spokenText:
          'Wer regelmäßig liest, begegnet vielen neuen Wörtern und erweitert dadurch seinen Wortschatz. Außerdem fällt es oft leichter, längere Texte zu verstehen. Ob ein Buch dick oder dünn ist, ist dabei weniger wichtig.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-breakfast',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ein ausgewogenes Frühstück liefert Energie für den Vormittag.',
        'Getränke gehören zu einem guten Frühstück dazu.',
      ],
      choices: <String>[
        'Ein ausgewogenes Frühstück liefert Energie für den Vormittag.',
        'Getränke gehören zu einem guten Frühstück dazu.',
        'Teller können bunt sein.',
        'Viele Menschen benutzen Löffel.',
      ],
      spokenText:
          'Ein ausgewogenes Frühstück kann Energie für den Vormittag liefern. Dazu gehört auch genug zu trinken. Welche Farbe der Teller hat, ist für die Wirkung des Frühstücks nicht entscheidend.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-trees',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Bäume spenden an heißen Tagen Schatten.',
        'Bäume bieten vielen Tieren Lebensraum.',
      ],
      choices: <String>[
        'Bäume spenden an heißen Tagen Schatten.',
        'Bäume bieten vielen Tieren Lebensraum.',
        'Baumrinde kann rau sein.',
        'Manche Blätter sind groß.',
      ],
      spokenText:
          'Bäume können Plätze im Sommer deutlich angenehmer machen, weil sie Schatten spenden. Außerdem bieten sie Vögeln und Insekten Lebensraum. Die genaue Form einzelner Blätter ist dafür nicht entscheidend.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-exercise',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Regelmäßige Bewegung stärkt den Körper.',
        'Bewegung kann helfen, sich danach besser zu konzentrieren.',
      ],
      choices: <String>[
        'Regelmäßige Bewegung stärkt den Körper.',
        'Bewegung kann helfen, sich danach besser zu konzentrieren.',
        'Turnschuhe haben Schnürsenkel.',
        'Sporthallen besitzen Türen.',
      ],
      spokenText:
          'Regelmäßige Bewegung stärkt Muskeln und Kreislauf. Nach einer aktiven Pause können sich viele Kinder außerdem wieder besser konzentrieren. Welche Schuhe man dabei trägt, ist für diese Hauptgedanken nicht entscheidend.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-compost',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Kompost macht aus Pflanzenresten nährstoffreiche Erde.',
        'Kompostieren kann Bioabfall sinnvoll verwerten.',
      ],
      choices: <String>[
        'Kompost macht aus Pflanzenresten nährstoffreiche Erde.',
        'Kompostieren kann Bioabfall sinnvoll verwerten.',
        'Kompostbehälter können braun sein.',
        'Ein Garten kann einen Zaun haben.',
      ],
      spokenText:
          'Auf dem Kompost werden Pflanzenreste nach und nach zu nährstoffreicher Erde. So kann ein Teil des Bioabfalls sinnvoll weiterverwendet werden. Farbe und Form des Kompostbehälters sind dafür nebensächlich.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-bike-route',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ein sicherer Schulweg braucht übersichtliche Querungen.',
        'Getrennte Radwege können gefährliche Situationen verringern.',
      ],
      choices: <String>[
        'Ein sicherer Schulweg braucht übersichtliche Querungen.',
        'Getrennte Radwege können gefährliche Situationen verringern.',
        'Straßenschilder sind oft aus Metall.',
        'Viele Fahrräder haben einen Ständer.',
      ],
      spokenText:
          'Auf einem sicheren Schulweg sollten Straßen an übersichtlichen Stellen überquert werden können. Getrennte Radwege können außerdem Konflikte mit Autos verringern. Die Farbe einzelner Verkehrsschilder ist dabei kein Hauptgedanke.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-library',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Eine Bücherei bietet Zugang zu vielen verschiedenen Medien.',
        'Ausleihen ermöglicht Nutzung ohne jedes Buch selbst zu kaufen.',
      ],
      choices: <String>[
        'Eine Bücherei bietet Zugang zu vielen verschiedenen Medien.',
        'Ausleihen ermöglicht Nutzung ohne jedes Buch selbst zu kaufen.',
        'Regale können unterschiedlich hoch sein.',
        'Bibliotheksausweise sind oft aus Kunststoff.',
      ],
      spokenText:
          'In einer Bücherei können viele unterschiedliche Bücher und andere Medien genutzt werden. Durch das Ausleihen muss man nicht jedes Buch selbst kaufen. Wie hoch die Regale sind, ist dafür nebensächlich.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-homework',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Gründe, die Amir wirklich nennt.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Eine Wochenübersicht macht Aufgaben planbarer.',
        'Kinder können ihre Zeit besser einteilen.',
      ],
      choices: <String>[
        'Eine Wochenübersicht macht Aufgaben planbarer.',
        'Kinder können ihre Zeit besser einteilen.',
        'Amir schreibt mit einem blauen Stift.',
        'Das Heft hat vier Ecken.',
      ],
      spokenText:
          'Amir meint: Eine Wochenübersicht für Hausaufgaben wäre hilfreich. Dann sehen wir früh, was ansteht, und können unsere Zeit besser einteilen.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-water',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Argumente für einen Wasserspender.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Kinder können ihre Flaschen in der Schule auffüllen.',
        'Weniger Einwegflaschen können nötig sein.',
      ],
      choices: <String>[
        'Kinder können ihre Flaschen in der Schule auffüllen.',
        'Weniger Einwegflaschen können nötig sein.',
        'Der Flur hat weiße Wände.',
        'Manche Flaschen sind durchsichtig.',
      ],
      spokenText:
          'Lea sagt: Ein Wasserspender wäre praktisch, weil wir unsere Flaschen direkt in der Schule auffüllen könnten. Dadurch müssten wir auch seltener Getränke in Einwegflaschen mitbringen.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-bike-rack',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Gründe für mehr Fahrradständer.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Mehr Fahrräder können ordentlich abgestellt werden.',
        'Die Wege vor dem Eingang bleiben eher frei.',
      ],
      choices: <String>[
        'Mehr Fahrräder können ordentlich abgestellt werden.',
        'Die Wege vor dem Eingang bleiben eher frei.',
        'Fahrräder haben zwei Räder.',
        'Der Eingang hat eine Glastür.',
      ],
      spokenText:
          'Jonas schlägt mehr Fahrradständer vor. Dann könnten mehr Räder ordentlich abgestellt werden und die Wege vor dem Schuleingang blieben eher frei.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-reading-time',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Gründe für eine feste Lesezeit.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Alle Kinder bekommen regelmäßig Zeit zum Lesen.',
        'Auch längere Bücher können Stück für Stück gelesen werden.',
      ],
      choices: <String>[
        'Alle Kinder bekommen regelmäßig Zeit zum Lesen.',
        'Auch längere Bücher können Stück für Stück gelesen werden.',
        'Bücher stehen in Regalen.',
        'Viele Seiten haben Seitenzahlen.',
      ],
      spokenText:
          'Mia sagt: Eine feste Lesezeit jede Woche wäre gut. Dann bekommt jedes Kind regelmäßig Zeit zum Lesen und auch längere Bücher können wir Stück für Stück schaffen.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-plants',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Gründe, die Nora wirklich nennt.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Pflanzen können den Klassenraum angenehmer wirken lassen.',
        'Die Klasse kann gemeinsam Verantwortung übernehmen.',
      ],
      choices: <String>[
        'Pflanzen können den Klassenraum angenehmer wirken lassen.',
        'Die Klasse kann gemeinsam Verantwortung übernehmen.',
        'Blumentöpfe können rund sein.',
        'Nora sitzt am Fenster.',
      ],
      spokenText:
          'Nora findet mehr Pflanzen im Klassenraum gut. Sie könnten den Raum angenehmer wirken lassen, und mit einem Gießdienst könnten wir gemeinsam Verantwortung übernehmen.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-playground',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die zwei Argumente für einen ruhigeren Pausenbereich.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Kinder können sich dort zurückziehen.',
        'Leise Gespräche oder Lesen werden leichter.',
      ],
      choices: <String>[
        'Kinder können sich dort zurückziehen.',
        'Leise Gespräche oder Lesen werden leichter.',
        'Der Hof hat einen Zaun.',
        'Ein Ball ist rund.',
      ],
      spokenText:
          'Ben sagt: Auf dem Schulhof sollte es auch einen ruhigen Bereich geben. Dort könnten sich Kinder zurückziehen und leichter lesen oder leise miteinander sprechen.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-class-jobs',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Gründe für wechselnde Klassendienste.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Aufgaben werden gerechter verteilt.',
        'Jedes Kind lernt verschiedene Verantwortungen kennen.',
      ],
      choices: <String>[
        'Aufgaben werden gerechter verteilt.',
        'Jedes Kind lernt verschiedene Verantwortungen kennen.',
        'Der Stundenplan hängt an der Wand.',
        'Kreide kann weiß sein.',
      ],
      spokenText:
          'Sara schlägt vor, die Klassendienste regelmäßig zu wechseln. So werden die Aufgaben gerechter verteilt und jedes Kind lernt verschiedene Verantwortungen kennen.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-digital-board',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die zwei Gründe für eine digitale Aufgabenübersicht.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Änderungen können schnell für alle sichtbar gemacht werden.',
        'Vergessene Aufgaben lassen sich leichter nachsehen.',
      ],
      choices: <String>[
        'Änderungen können schnell für alle sichtbar gemacht werden.',
        'Vergessene Aufgaben lassen sich leichter nachsehen.',
        'Der Bildschirm ist rechteckig.',
        'Die Klasse hat zwanzig Stühle.',
      ],
      spokenText:
          'Tom meint: Eine digitale Aufgabenübersicht könnte helfen. Änderungen wären schnell für alle sichtbar, und wer etwas vergessen hat, könnte dort noch einmal nachsehen.',
    ),
  ];
}
