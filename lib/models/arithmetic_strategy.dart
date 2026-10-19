import 'dart:math';

import 'math_fact.dart';


enum ArithmeticTaskFamily {
  basic,
  additionNoRegroup,
  additionOnesRegroup,
  additionHigherRegroup,
  additionMultiRegroup,
  subtractionNoRegroup,
  subtractionOnesBorrow,
  subtractionHigherBorrow,
  subtractionMultiBorrow,
  multiplicationPlaceShift,
  multiplicationPartialProducts,
  divisionPlaceShift,
  divisionPartialQuotients,
}

extension ArithmeticTaskFamilyX on ArithmeticTaskFamily {
  MathOperation? get operation => switch (this) {
        ArithmeticTaskFamily.basic => null,
        ArithmeticTaskFamily.additionNoRegroup ||
        ArithmeticTaskFamily.additionOnesRegroup ||
        ArithmeticTaskFamily.additionHigherRegroup ||
        ArithmeticTaskFamily.additionMultiRegroup => MathOperation.plus,
        ArithmeticTaskFamily.subtractionNoRegroup ||
        ArithmeticTaskFamily.subtractionOnesBorrow ||
        ArithmeticTaskFamily.subtractionHigherBorrow ||
        ArithmeticTaskFamily.subtractionMultiBorrow => MathOperation.minus,
        ArithmeticTaskFamily.multiplicationPlaceShift ||
        ArithmeticTaskFamily.multiplicationPartialProducts =>
          MathOperation.multiply,
        ArithmeticTaskFamily.divisionPlaceShift ||
        ArithmeticTaskFamily.divisionPartialQuotients => MathOperation.divide,
      };

  String get label => switch (this) {
        ArithmeticTaskFamily.basic => 'Grundaufgabe',
        ArithmeticTaskFamily.additionNoRegroup =>
          'Addition ohne Stellenübergang',
        ArithmeticTaskFamily.additionOnesRegroup =>
          'Addition mit Einerübergang',
        ArithmeticTaskFamily.additionHigherRegroup =>
          'Addition mit höherem Stellenübergang',
        ArithmeticTaskFamily.additionMultiRegroup =>
          'Addition mit mehreren Stellenübergängen',
        ArithmeticTaskFamily.subtractionNoRegroup =>
          'Subtraktion ohne Entbündeln',
        ArithmeticTaskFamily.subtractionOnesBorrow =>
          'Subtraktion mit Entbündeln bei den Einern',
        ArithmeticTaskFamily.subtractionHigherBorrow =>
          'Subtraktion mit Entbündeln an höherer Stelle',
        ArithmeticTaskFamily.subtractionMultiBorrow =>
          'Subtraktion mit mehreren Entbündelungen',
        ArithmeticTaskFamily.multiplicationPlaceShift =>
          'Malnehmen mit glatten Zehnern/Hundertern',
        ArithmeticTaskFamily.multiplicationPartialProducts =>
          'Malnehmen mit Teilprodukten',
        ArithmeticTaskFamily.divisionPlaceShift =>
          'Teilen mit glatten Stellenwerten',
        ArithmeticTaskFamily.divisionPartialQuotients =>
          'Teilen mit Teilquotienten',
      };

  String get parentDescription => switch (this) {
        ArithmeticTaskFamily.basic => 'Grundaufgaben',
        ArithmeticTaskFamily.additionNoRegroup =>
          'mehrstellige Addition ohne Übertrag',
        ArithmeticTaskFamily.additionOnesRegroup =>
          'mehrstellige Addition mit Übertrag von den Einern zu den Zehnern',
        ArithmeticTaskFamily.additionHigherRegroup =>
          'mehrstellige Addition mit Übertrag an Zehner-/Hunderterstelle',
        ArithmeticTaskFamily.additionMultiRegroup =>
          'mehrstellige Addition mit mehreren Überträgen',
        ArithmeticTaskFamily.subtractionNoRegroup =>
          'mehrstellige Subtraktion ohne Entbündeln',
        ArithmeticTaskFamily.subtractionOnesBorrow =>
          'mehrstellige Subtraktion mit Entbündeln von Zehnern zu Einern',
        ArithmeticTaskFamily.subtractionHigherBorrow =>
          'mehrstellige Subtraktion mit Entbündeln an Zehner-/Hunderterstelle',
        ArithmeticTaskFamily.subtractionMultiBorrow =>
          'mehrstellige Subtraktion mit mehreren Entbündelungen',
        ArithmeticTaskFamily.multiplicationPlaceShift =>
          'Multiplikation mit glatten Zehnern/Hundertern',
        ArithmeticTaskFamily.multiplicationPartialProducts =>
          'mehrstellige Multiplikation über Teilprodukte',
        ArithmeticTaskFamily.divisionPlaceShift =>
          'Division mit glatten Stellenwerten',
        ArithmeticTaskFamily.divisionPartialQuotients =>
          'mehrstellige Division über Teilquotienten',
      };
}

/// Shared analysis for multi-step arithmetic. It deliberately stays independent
/// from widgets so generation, diagnosis, help and touch interaction agree on
/// the same decomposition.
class ArithmeticStrategy {
  const ArithmeticStrategy._();

  static bool usesPlaceValueStrategy(MathFact fact) => switch (fact.operation) {
        MathOperation.plus || MathOperation.minus =>
          max(max(fact.a, fact.b), fact.result.abs()) > 100,
        MathOperation.multiply => fact.a > 10 || fact.b > 10,
        MathOperation.divide => fact.a > 100 || fact.result > 10,
      };


  static ArithmeticTaskFamily familyFor(MathFact fact) {
    if (!usesPlaceValueStrategy(fact)) return ArithmeticTaskFamily.basic;
    return switch (fact.operation) {
      MathOperation.plus => switch (additionCarryPlaces(fact)) {
          [] => ArithmeticTaskFamily.additionNoRegroup,
          [10] => ArithmeticTaskFamily.additionOnesRegroup,
          [final place] when place > 10 =>
            ArithmeticTaskFamily.additionHigherRegroup,
          _ => ArithmeticTaskFamily.additionMultiRegroup,
        },
      MathOperation.minus => switch (subtractionBorrowPlaces(fact)) {
          [] => ArithmeticTaskFamily.subtractionNoRegroup,
          [10] => ArithmeticTaskFamily.subtractionOnesBorrow,
          [final place] when place > 10 =>
            ArithmeticTaskFamily.subtractionHigherBorrow,
          _ => ArithmeticTaskFamily.subtractionMultiBorrow,
        },
      MathOperation.multiply => multiplicationOperandChunks(fact).length <= 1
          ? ArithmeticTaskFamily.multiplicationPlaceShift
          : ArithmeticTaskFamily.multiplicationPartialProducts,
      MathOperation.divide => divisionQuotientChunks(fact).length <= 1
          ? ArithmeticTaskFamily.divisionPlaceShift
          : ArithmeticTaskFamily.divisionPartialQuotients,
    };
  }

  static bool matchesFamily(MathFact fact, ArithmeticTaskFamily family) =>
      familyFor(fact) == family;

  static List<int> placeValueChunks(int value) {
    var remaining = value.abs();
    if (remaining == 0) return const <int>[];
    var place = 1;
    while (place <= remaining ~/ 10) {
      place *= 10;
    }
    final chunks = <int>[];
    while (place >= 1) {
      final digit = remaining ~/ place;
      if (digit > 0) {
        final chunk = digit * place;
        chunks.add(chunk);
        remaining -= chunk;
      }
      place ~/= 10;
    }
    return chunks;
  }

  static List<int> additionCarryPlaces(MathFact fact) {
    if (fact.operation != MathOperation.plus) return const <int>[];
    final places = <int>[];
    var place = 1;
    var carry = 0;
    final largest = max(fact.a, fact.b);
    while (place <= max(1, largest)) {
      final digitA = (fact.a ~/ place) % 10;
      final digitB = (fact.b ~/ place) % 10;
      final sum = digitA + digitB + carry;
      carry = sum >= 10 ? 1 : 0;
      if (carry > 0) places.add(place * 10);
      place *= 10;
    }
    return places;
  }

  static List<int> subtractionBorrowPlaces(MathFact fact) {
    if (fact.operation != MathOperation.minus) return const <int>[];
    final places = <int>[];
    var place = 1;
    var borrow = 0;
    final largest = max(fact.a, fact.b);
    while (place <= max(1, largest)) {
      final digitA = (fact.a ~/ place) % 10 - borrow;
      final digitB = (fact.b ~/ place) % 10;
      if (digitA < digitB) {
        places.add(place * 10);
        borrow = 1;
      } else {
        borrow = 0;
      }
      place *= 10;
    }
    return places;
  }

  static int digitwiseAbsoluteSubtraction(MathFact fact) {
    var result = 0;
    var place = 1;
    final largest = max(fact.a, fact.b);
    while (place <= max(1, largest)) {
      final digitA = (fact.a ~/ place) % 10;
      final digitB = (fact.b ~/ place) % 10;
      result += (digitA - digitB).abs() * place;
      place *= 10;
    }
    return result;
  }

  static (int large, int factor) multiplicationParts(MathFact fact) {
    if (fact.a >= fact.b) return (fact.a, fact.b);
    return (fact.b, fact.a);
  }

  static List<int> multiplicationOperandChunks(MathFact fact) {
    if (fact.operation != MathOperation.multiply) return const <int>[];
    return placeValueChunks(multiplicationParts(fact).$1);
  }

  static List<int> multiplicationPartialProducts(MathFact fact) {
    if (fact.operation != MathOperation.multiply) return const <int>[];
    final parts = multiplicationParts(fact);
    return placeValueChunks(parts.$1)
        .map((chunk) => chunk * parts.$2)
        .toList(growable: false);
  }

  static List<int> divisionQuotientChunks(MathFact fact) {
    if (fact.operation != MathOperation.divide || fact.b == 0) {
      return const <int>[];
    }
    return placeValueChunks(fact.result);
  }

  static List<int> divisionDividendChunks(MathFact fact) {
    if (fact.operation != MathOperation.divide || fact.b == 0) {
      return const <int>[];
    }
    return divisionQuotientChunks(fact)
        .map((quotientChunk) => quotientChunk * fact.b)
        .toList(growable: false);
  }

  static bool looksLikePartialStrategy(MathFact fact, int actual) {
    if (actual == fact.result) return false;
    switch (fact.operation) {
      case MathOperation.plus:
      case MathOperation.minus:
        final chunks = placeValueChunks(fact.b);
        if (chunks.length < 2) return false;
        var running = fact.a;
        for (var index = 0; index < chunks.length - 1; index++) {
          running = fact.operation == MathOperation.plus
              ? running + chunks[index]
              : running - chunks[index];
          if (actual == running) return true;
        }
        return chunks.any(
          (chunk) => fact.operation == MathOperation.plus
              ? actual == fact.result - chunk
              : actual == fact.result + chunk,
        );
      case MathOperation.multiply:
        final partials = multiplicationPartialProducts(fact);
        if (partials.length < 2) return false;
        if (partials.contains(actual)) return true;
        return partials.any((part) => actual == fact.result - part);
      case MathOperation.divide:
        final partials = divisionQuotientChunks(fact);
        if (partials.length < 2) return false;
        if (partials.contains(actual)) return true;
        return partials.any((part) => actual == fact.result - part);
    }
  }

  static String difficultyLabel(MathFact fact) => familyFor(fact).label;

  static String placeLabel(int chunk) {
    final value = chunk.abs();
    if (value == 0) return 'Teil';
    var place = 1;
    while (place <= value ~/ 10) {
      place *= 10;
    }
    return switch (place) {
      1 => 'Einer',
      10 => 'Zehner',
      100 => 'Hunderter',
      1000 => 'Tausender',
      10000 => 'Zehntausender',
      100000 => 'Hunderttausender',
      _ => 'Stellenwert',
    };
  }
}
