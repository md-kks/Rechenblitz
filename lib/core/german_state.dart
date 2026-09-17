enum GermanState {
  badenWuerttemberg,
  bavaria,
  berlin,
  brandenburg,
  bremen,
  hamburg,
  hesse,
  mecklenburgVorpommern,
  lowerSaxony,
  northRhineWestphalia,
  rhinelandPalatinate,
  saarland,
  saxony,
  saxonyAnhalt,
  schleswigHolstein,
  thuringia,
}

extension GermanStateX on GermanState {
  String get label => switch (this) {
    GermanState.badenWuerttemberg => 'Baden-Württemberg',
    GermanState.bavaria => 'Bayern',
    GermanState.berlin => 'Berlin',
    GermanState.brandenburg => 'Brandenburg',
    GermanState.bremen => 'Bremen',
    GermanState.hamburg => 'Hamburg',
    GermanState.hesse => 'Hessen',
    GermanState.mecklenburgVorpommern => 'Mecklenburg-Vorpommern',
    GermanState.lowerSaxony => 'Niedersachsen',
    GermanState.northRhineWestphalia => 'Nordrhein-Westfalen',
    GermanState.rhinelandPalatinate => 'Rheinland-Pfalz',
    GermanState.saarland => 'Saarland',
    GermanState.saxony => 'Sachsen',
    GermanState.saxonyAnhalt => 'Sachsen-Anhalt',
    GermanState.schleswigHolstein => 'Schleswig-Holstein',
    GermanState.thuringia => 'Thüringen',
  };
}
