import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanListeningTouchTaskCatalog {
  const GermanListeningTouchTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g1-listen-mark-park',
      competencyId: GermanCompetencyId.listeningComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Hör genau zu. Markiere die zwei Dinge, die Mia mitnimmt.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['roter Ball', 'gelbe Decke'],
      choices: <String>[
        'roter Ball',
        'gelbe Decke',
        'blauer Eimer',
        'grünes Buch',
      ],
      spokenText:
          'Mia nimmt einen roten Ball und eine gelbe Decke mit in den Park.',
    ),
    GermanTask(
      id: 'g1-listen-mark-breakfast',
      competencyId: GermanCompetencyId.listeningComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere, was Ben beim Frühstück isst und trinkt.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Kakao', 'Brot'],
      choices: <String>['Kakao', 'Brot', 'Apfel', 'Saft'],
      spokenText:
          'Ben trinkt zum Frühstück Kakao und isst ein Brot. Den Apfel nimmt er später mit.',
    ),
    GermanTask(
      id: 'g1-listen-mark-desk',
      competencyId: GermanCompetencyId.listeningComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere die zwei Dinge, die Lea auf den Tisch legt.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Heft', 'Stift'],
      choices: <String>['Heft', 'Stift', 'Schere', 'Lineal'],
      spokenText:
          'Lea legt ihr Heft und ihren Stift auf den Tisch. Die Schere bleibt im Ranzen.',
    ),
    GermanTask(
      id: 'g1-listen-mark-weather',
      competencyId: GermanCompetencyId.listeningComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere die zwei Aussagen, die du gehört hast.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Am Morgen regnet es.',
        'Mia nimmt einen Schirm mit.',
      ],
      choices: <String>[
        'Am Morgen regnet es.',
        'Mia nimmt einen Schirm mit.',
        'Am Morgen schneit es.',
        'Mia nimmt einen Ball mit.',
      ],
      spokenText:
          'Am Morgen regnet es. Mia nimmt deshalb einen Schirm mit. Am Nachmittag scheint die Sonne.',
    ),
    GermanTask(
      id: 'g1-talk-mark-soft',
      competencyId: GermanCompetencyId.conversationRules,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere zwei gute Reaktionen.',
      prompt: 'Hör die Situation.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ich höre aufmerksam zu.',
        'Ich frage freundlich nach.',
      ],
      choices: <String>[
        'Ich höre aufmerksam zu.',
        'Ich frage freundlich nach.',
        'Ich unterbreche sofort.',
        'Ich rufe dazwischen.',
      ],
      spokenText:
          'Nora erzählt etwas sehr leise. Ben hat den letzten Satz nicht verstanden.',
    ),
    GermanTask(
      id: 'g1-talk-mark-group',
      competencyId: GermanCompetencyId.conversationRules,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere zwei Regeln, die jetzt helfen.',
      prompt: 'Hör die Situation.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Wir sprechen nacheinander.',
        'Wir hören der anderen Idee zu.',
      ],
      choices: <String>[
        'Wir sprechen nacheinander.',
        'Wir hören der anderen Idee zu.',
        'Alle reden gleichzeitig.',
        'Die lauteste Person entscheidet.',
      ],
      spokenText:
          'Vier Kinder planen gemeinsam ein Plakat. Zwei Kinder möchten gleichzeitig ihre Idee erklären.',
    ),
    GermanTask(
      id: 'g1-talk-mark-disagree',
      competencyId: GermanCompetencyId.conversationRules,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere zwei gute Reaktionen auf die andere Meinung.',
      prompt: 'Hör die Situation.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ich lasse das Kind ausreden.',
        'Ich sage ruhig, warum ich anders denke.',
      ],
      choices: <String>[
        'Ich lasse das Kind ausreden.',
        'Ich sage ruhig, warum ich anders denke.',
        'Ich lache die Idee aus.',
        'Ich werde extra laut.',
      ],
      spokenText:
          'Mila findet, die Gruppe soll zuerst malen. Du würdest lieber zuerst schreiben.',
    ),
    GermanTask(
      id: 'g1-talk-mark-word',
      competencyId: GermanCompetencyId.conversationRules,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere zwei Reaktionen, die dem erzählenden Kind helfen.',
      prompt: 'Hör die Situation.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ich warte geduldig.',
        'Ich mache Mut weiterzuerzählen.',
      ],
      choices: <String>[
        'Ich warte geduldig.',
        'Ich mache Mut weiterzuerzählen.',
        'Ich sage das Wort sofort für das Kind.',
        'Ich beginne ein anderes Gespräch.',
      ],
      spokenText:
          'Ein Kind erzählt von seinem Wochenende und sucht gerade nach einem Wort.',
    ),
    GermanTask(
      id: 'g2-retell-order-seed',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Ordne die drei Schritte der Geschichte.',
      prompt: 'Hör die Geschichte.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Lina füllt Erde in einen Topf Sie setzt einen Samen ein Sie gießt den Samen',
      ],
      choices: <String>[
        'Lina füllt Erde in einen Topf',
        'Sie setzt einen Samen ein',
        'Sie gießt den Samen',
      ],
      spokenText:
          'Lina füllt zuerst Erde in einen Topf. Dann setzt sie einen Samen hinein. Zum Schluss gießt sie ihn vorsichtig.',
    ),
    GermanTask(
      id: 'g2-retell-order-lunchbox',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Ordne die drei wichtigsten Ereignisse.',
      prompt: 'Hör die Geschichte.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Tom bemerkt die vergessene Brotdose Er sagt im Sekretariat Bescheid Seine Mutter bringt die Dose',
      ],
      choices: <String>[
        'Tom bemerkt die vergessene Brotdose',
        'Er sagt im Sekretariat Bescheid',
        'Seine Mutter bringt die Dose',
      ],
      spokenText:
          'In der Pause bemerkt Tom, dass seine Brotdose zu Hause liegt. Er sagt im Sekretariat Bescheid. Wenig später bringt seine Mutter die Dose vorbei.',
    ),
    GermanTask(
      id: 'g2-retell-order-boat',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Ordne die Ereignisse so, wie sie passiert sind.',
      prompt: 'Hör die Geschichte.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Leo faltet ein Papierboot Er setzt es ins Wasser Das Boot bleibt an einem Ast hängen',
      ],
      choices: <String>[
        'Leo faltet ein Papierboot',
        'Er setzt es ins Wasser',
        'Das Boot bleibt an einem Ast hängen',
      ],
      spokenText:
          'Leo faltet aus Papier ein kleines Boot. Danach setzt er es in den Bach. Wenig später bleibt das Boot an einem Ast hängen.',
    ),
    GermanTask(
      id: 'g2-retell-order-card',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Ordne die Arbeitsschritte der Geschichte.',
      prompt: 'Hör die Geschichte.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Mia schneidet Papier aus Sie faltet die Karte Sie klebt einen Stern darauf',
      ],
      choices: <String>[
        'Mia schneidet Papier aus',
        'Sie faltet die Karte',
        'Sie klebt einen Stern darauf',
      ],
      spokenText:
          'Mia schneidet zuerst ein Stück Papier aus. Dann faltet sie es zu einer Karte. Zum Schluss klebt sie einen Stern auf die Vorderseite.',
    ),
    GermanTask(
      id: 'g3-retell-order-experiment',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne die wichtigsten Ereignisse der gehörten Geschichte.',
      prompt: 'Hör die Geschichte.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Die Gruppe baut den Versuch auf Sie beobachtet eine unerwartete Reaktion Sie verändert den Aufbau und testet erneut',
      ],
      choices: <String>[
        'Die Gruppe baut den Versuch auf',
        'Sie beobachtet eine unerwartete Reaktion',
        'Sie verändert den Aufbau und testet erneut',
      ],
      spokenText:
          'Die Gruppe baut zuerst ihren Versuch nach Plan auf. Beim Test beobachtet sie eine unerwartete Reaktion. Danach verändert sie einen Teil des Aufbaus und führt den Versuch noch einmal durch.',
    ),
    GermanTask(
      id: 'g3-retell-order-key',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne die drei Kernereignisse.',
      prompt: 'Hör die Geschichte.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Nora bemerkt den fehlenden Schlüssel Sie geht ihren Weg zurück Sie findet den Schlüssel beim Fahrradständer',
      ],
      choices: <String>[
        'Nora bemerkt den fehlenden Schlüssel',
        'Sie geht ihren Weg zurück',
        'Sie findet den Schlüssel beim Fahrradständer',
      ],
      spokenText:
          'Vor der Haustür merkt Nora, dass ihr Schlüssel fehlt. Sie geht den Weg von der Schule noch einmal zurück. Beim Fahrradständer entdeckt sie den Schlüssel schließlich auf dem Boden.',
    ),
    GermanTask(
      id: 'g3-retell-order-rain',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne den Ablauf der Geschichte.',
      prompt: 'Hör die Geschichte.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Beim Ausflug beginnt es stark zu regnen Die Klasse sucht Schutz in einer Hütte Nach dem Schauer setzt sie den Weg fort',
      ],
      choices: <String>[
        'Beim Ausflug beginnt es stark zu regnen',
        'Die Klasse sucht Schutz in einer Hütte',
        'Nach dem Schauer setzt sie den Weg fort',
      ],
      spokenText:
          'Während des Ausflugs beginnt es plötzlich stark zu regnen. Die Klasse läuft zu einer kleinen Schutzhütte. Als der Schauer vorbei ist, setzt sie ihren Weg fort.',
    ),
    GermanTask(
      id: 'g3-retell-order-newspaper',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne die Arbeitsschritte aus dem Hörtext.',
      prompt: 'Hör die Geschichte.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Die Kinder sammeln Themen Sie schreiben ihre Beiträge Sie prüfen und gestalten die Zeitung',
      ],
      choices: <String>[
        'Die Kinder sammeln Themen',
        'Sie schreiben ihre Beiträge',
        'Sie prüfen und gestalten die Zeitung',
      ],
      spokenText:
          'Für die Klassenzeitung sammeln die Kinder zuerst mögliche Themen. Danach schreiben sie ihre Beiträge. Zum Schluss prüfen sie die Texte und gestalten gemeinsam die Seiten.',
    ),
    GermanTask(
      id: 'g3-present-order-bees',
      competencyId: GermanCompetencyId.presentationStructure,
      recommendedFromGrade: GradeLevel.third,
      instruction:
          'Ordne die Teile der Präsentation in der gehörten Reihenfolge.',
      prompt: 'Hör den kurzen Vortrag.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>['Thema nennen Nutzen erklären Beispiel geben'],
      choices: <String>['Thema nennen', 'Nutzen erklären', 'Beispiel geben'],
      spokenText:
          'Heute geht es um Bienen. Zuerst erkläre ich, warum sie für Pflanzen wichtig sind. Danach zeige ich am Apfelbaum ein Beispiel.',
    ),
    GermanTask(
      id: 'g3-present-order-book',
      competencyId: GermanCompetencyId.presentationStructure,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne die drei Präsentationsteile.',
      prompt: 'Hör den kurzen Vortrag.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Titel und Autor nennen Inhalt kurz erklären Empfehlung geben',
      ],
      choices: <String>[
        'Titel und Autor nennen',
        'Inhalt kurz erklären',
        'Empfehlung geben',
      ],
      spokenText:
          'Ich stelle euch zuerst den Titel und den Autor meines Buches vor. Danach erzähle ich kurz, worum es geht. Am Ende sage ich, wem ich das Buch empfehlen würde.',
    ),
    GermanTask(
      id: 'g3-present-order-weather',
      competencyId: GermanCompetencyId.presentationStructure,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne die Teile so, wie sie im Vortrag vorkommen.',
      prompt: 'Hör den kurzen Vortrag.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Frage als Einstieg zwei Fakten erklären Schlussgedanken nennen',
      ],
      choices: <String>[
        'Frage als Einstieg',
        'zwei Fakten erklären',
        'Schlussgedanken nennen',
      ],
      spokenText:
          'Warum entsteht eigentlich Regen? Mit dieser Frage beginne ich. Danach erkläre ich zwei wichtige Fakten zur Wolkenbildung. Zum Schluss fasse ich den wichtigsten Gedanken zusammen.',
    ),
    GermanTask(
      id: 'g3-present-order-project',
      competencyId: GermanCompetencyId.presentationStructure,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne die Präsentationsteile in der gehörten Reihenfolge.',
      prompt: 'Hör den kurzen Vortrag.',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Ziel vorstellen Vorgehen erklären Ergebnis zeigen',
      ],
      choices: <String>[
        'Ziel vorstellen',
        'Vorgehen erklären',
        'Ergebnis zeigen',
      ],
      spokenText:
          'Zuerst sage ich, was wir mit unserem Projekt erreichen wollten. Danach erkläre ich unser Vorgehen. Am Ende zeige ich euch das fertige Ergebnis.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-garden',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Regenwasser kann im Schulgarten genutzt werden.',
        'Das spart Leitungswasser.',
      ],
      choices: <String>[
        'Regenwasser kann im Schulgarten genutzt werden.',
        'Das spart Leitungswasser.',
        'Die Regentonne ist grün.',
        'Tom trägt Gummistiefel.',
      ],
      spokenText:
          'Die Klasse sammelt Regenwasser in einer Tonne und nutzt es für den Schulgarten. Dadurch muss sie weniger Leitungswasser zum Gießen verwenden. Die Tonne steht neben dem Geräteschuppen.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-sleep',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ausreichender Schlaf hilft beim Konzentrieren.',
        'Bildschirme kurz vor dem Schlafen können das Einschlafen erschweren.',
      ],
      choices: <String>[
        'Ausreichender Schlaf hilft beim Konzentrieren.',
        'Bildschirme kurz vor dem Schlafen können das Einschlafen erschweren.',
        'Ein Wecker kann blau sein.',
        'Viele Betten haben Kissen.',
      ],
      spokenText:
          'Wer ausreichend schläft, kann sich am nächsten Tag oft besser konzentrieren. Helles Bildschirmlicht kurz vor dem Schlafengehen kann dagegen das Einschlafen erschweren. Eine ruhige Abendroutine kann helfen.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-bees',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Bienen bestäuben viele Blüten.',
        'Blühende Pflanzen helfen Bienen bei der Nahrungssuche.',
      ],
      choices: <String>[
        'Bienen bestäuben viele Blüten.',
        'Blühende Pflanzen helfen Bienen bei der Nahrungssuche.',
        'Bienen haben sechs Beine.',
        'Honiggläser haben Deckel.',
      ],
      spokenText:
          'Bienen bestäuben viele Blüten und helfen dadurch Pflanzen bei der Fortpflanzung. Gärten mit vielen blühenden Pflanzen bieten ihnen Nahrung. Einzelne Blütenfarben sind dafür weniger wichtig als ein vielfältiges Angebot.',
    ),
    GermanTask(
      id: 'g4-listen-main-mark-bike',
      competencyId: GermanCompetencyId.listeningMainIdeas,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Hauptaussagen des Hörtexts.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ein Fahrradhelm schützt den Kopf.',
        'Ein gut passender Helm muss richtig eingestellt sein.',
      ],
      choices: <String>[
        'Ein Fahrradhelm schützt den Kopf.',
        'Ein gut passender Helm muss richtig eingestellt sein.',
        'Fahrräder können Klingeln haben.',
        'Helme gibt es in vielen Farben.',
      ],
      spokenText:
          'Ein Fahrradhelm kann den Kopf bei einem Sturz schützen. Dafür muss er gut passen und richtig eingestellt sein. Farbe und Muster sind für die Schutzwirkung nicht entscheidend.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-trees',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Gründe, die Jana wirklich nennt.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Bäume spenden Schatten.',
        'Bäume bieten Tieren Lebensraum.',
      ],
      choices: <String>[
        'Bäume spenden Schatten.',
        'Bäume bieten Tieren Lebensraum.',
        'Der Schulhof ist rechteckig.',
        'Jana mag grüne Stifte.',
      ],
      spokenText:
          'Jana sagt: Ich wäre dafür, auf dem Schulhof mehr Bäume zu pflanzen. Sie spenden im Sommer Schatten und bieten außerdem Vögeln und Insekten Lebensraum.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-train',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die zwei Argumente, die Malik für den Zug nennt.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Im Zug kann die Klasse zusammen sitzen.',
        'Die Fahrt verursacht weniger Autoverkehr.',
      ],
      choices: <String>[
        'Im Zug kann die Klasse zusammen sitzen.',
        'Die Fahrt verursacht weniger Autoverkehr.',
        'Der Bahnhof hat eine Uhr.',
        'Malik besitzt einen Rucksack.',
      ],
      spokenText:
          'Malik meint: Für den Ausflug sollten wir den Zug nehmen. Dann kann die Klasse während der Fahrt zusammen sitzen, und wir verursachen weniger Autoverkehr.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-calendar',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die zwei Gründe, die Lea für einen Klassenkalender nennt.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Termine werden nicht so leicht vergessen.',
        'Alle können dieselben Absprachen sehen.',
      ],
      choices: <String>[
        'Termine werden nicht so leicht vergessen.',
        'Alle können dieselben Absprachen sehen.',
        'Der Kalender kann bunt sein.',
        'Lea schreibt gern mit Füller.',
      ],
      spokenText:
          'Lea sagt: Ein gemeinsamer Klassenkalender wäre hilfreich. Dann vergessen wir wichtige Termine nicht so leicht, und alle können dieselben Absprachen sehen.',
    ),
    GermanTask(
      id: 'g4-discuss-mark-library',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die zwei Gründe für eine Ruhezone in der Bücherei.',
      prompt: 'Hör den Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Kinder können sich besser konzentrieren.',
        'Andere Bereiche können für Gespräche genutzt werden.',
      ],
      choices: <String>[
        'Kinder können sich besser konzentrieren.',
        'Andere Bereiche können für Gespräche genutzt werden.',
        'Die Regale sind aus Holz.',
        'Die Bücherei hat viele Fenster.',
      ],
      spokenText:
          'Ben schlägt vor: In der Bücherei sollte es eine Ruhezone geben. Dort können sich Kinder besser konzentrieren. Für Gespräche könnten wir weiterhin einen anderen Bereich nutzen.',
    ),
  ];
}
