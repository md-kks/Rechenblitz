import 'dart:math';

import 'math_fact.dart';

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

  static String difficultyLabel(MathFact fact) {
    if (!usesPlaceValueStrategy(fact)) return 'Grundaufgabe';
    return switch (fact.operation) {
      MathOperation.plus => additionCarryPlaces(fact).isEmpty
          ? 'Stellenweise Addition'
          : additionCarryPlaces(fact).length == 1
              ? 'Addition mit einem Übergang'
              : 'Addition mit mehreren Übergängen',
      MathOperation.minus => subtractionBorrowPlaces(fact).isEmpty
          ? 'Stellenweise Subtraktion'
          : subtractionBorrowPlaces(fact).length == 1
              ? 'Subtraktion mit einem Entbündeln'
              : 'Subtraktion mit mehreren Entbündelungen',
      MathOperation.multiply =>
        multiplicationOperandChunks(fact).length <= 1
            ? 'Malnehmen mit Stellenwertverschiebung'
            : 'Malnehmen mit Teilprodukten',
      MathOperation.divide => divisionQuotientChunks(fact).length <= 1
          ? 'Teilen mit Stellenwertverschiebung'
          : 'Teilen mit Teilquotienten',
    };
  }

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
