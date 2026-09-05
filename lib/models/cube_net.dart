import 'dart:math';

class GridCell {
  const GridCell(this.x, this.y);

  final int x;
  final int y;

  GridCell translate(int dx, int dy) => GridCell(x + dx, y + dy);

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class CubeNetPattern {
  const CubeNetPattern({
    required this.cells,
    required this.foldable,
  });

  final List<GridCell> cells;
  final bool foldable;

  String get key {
    final normalized = CubeNetValidator.normalize(cells);
    return normalized.map((cell) => '${cell.x},${cell.y}').join(';');
  }
}

class CubeNetValidator {
  const CubeNetValidator._();

  static bool isFoldable(List<GridCell> cells) {
    final unique = cells.toSet();
    if (unique.length != 6 || !_connected(unique)) return false;

    final orientations = <GridCell, _Orientation>{
      unique.first: const _Orientation(
        normal: _Vec3(0, 0, 1),
        up: _Vec3(0, 1, 0),
        right: _Vec3(1, 0, 0),
      ),
    };
    final queue = <GridCell>[unique.first];

    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      final current = orientations[cell]!;

      for (final move in moves) {
        final neighbor = cell.translate(move.dx, move.dy);
        if (!unique.contains(neighbor)) continue;

        final expected = current.fold(move.dx, move.dy);
        final existing = orientations[neighbor];
        if (existing != null) {
          if (existing != expected) return false;
          continue;
        }
        orientations[neighbor] = expected;
        queue.add(neighbor);
      }
    }

    if (orientations.length != 6) return false;
    return orientations.values.map((value) => value.normal).toSet().length == 6;
  }

  static List<GridCell> normalize(Iterable<GridCell> cells) {
    final list = cells.toList();
    if (list.isEmpty) return const [];
    final minX = list.map((cell) => cell.x).reduce(min);
    final minY = list.map((cell) => cell.y).reduce(min);
    final normalized = list
        .map((cell) => GridCell(cell.x - minX, cell.y - minY))
        .toList()
      ..sort((a, b) {
        final y = a.y.compareTo(b.y);
        return y != 0 ? y : a.x.compareTo(b.x);
      });
    return normalized;
  }

  static bool _connected(Set<GridCell> cells) {
    if (cells.isEmpty) return false;
    final seen = <GridCell>{cells.first};
    final queue = <GridCell>[cells.first];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final move in moves) {
        final next = current.translate(move.dx, move.dy);
        if (cells.contains(next) && seen.add(next)) queue.add(next);
      }
    }
    return seen.length == cells.length;
  }

  static const moves = <({int dx, int dy})>[
    (dx: 1, dy: 0),
    (dx: -1, dy: 0),
    (dx: 0, dy: -1),
    (dx: 0, dy: 1),
  ];
}

class CubeNetGenerator {
  CubeNetGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  CubeNetPattern generate({bool? foldable}) {
    final wanted = foldable ?? _random.nextBool();

    for (var attempt = 0; attempt < 500; attempt++) {
      final cells = <GridCell>{const GridCell(0, 0)};
      while (cells.length < 6) {
        final origin = cells.elementAt(_random.nextInt(cells.length));
        final move = CubeNetValidator.moves[
            _random.nextInt(CubeNetValidator.moves.length)];
        cells.add(origin.translate(move.dx, move.dy));
      }
      final normalized = CubeNetValidator.normalize(cells);
      final valid = CubeNetValidator.isFoldable(normalized);
      if (valid == wanted) {
        return CubeNetPattern(cells: normalized, foldable: valid);
      }
    }

    final fallback = wanted
        ? const [
            GridCell(1, 0),
            GridCell(0, 1),
            GridCell(1, 1),
            GridCell(2, 1),
            GridCell(3, 1),
            GridCell(1, 2),
          ]
        : const [
            GridCell(0, 0),
            GridCell(1, 0),
            GridCell(2, 0),
            GridCell(0, 1),
            GridCell(1, 1),
            GridCell(2, 1),
          ];
    return CubeNetPattern(
      cells: fallback,
      foldable: CubeNetValidator.isFoldable(fallback),
    );
  }
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  final int x;
  final int y;
  final int z;

  _Vec3 operator -() => _Vec3(-x, -y, -z);

  @override
  bool operator ==(Object other) =>
      other is _Vec3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);
}

class _Orientation {
  const _Orientation({
    required this.normal,
    required this.up,
    required this.right,
  });

  final _Vec3 normal;
  final _Vec3 up;
  final _Vec3 right;

  _Orientation fold(int dx, int dy) {
    if (dx == 1) {
      return _Orientation(normal: right, up: up, right: -normal);
    }
    if (dx == -1) {
      return _Orientation(normal: -right, up: up, right: normal);
    }
    if (dy == -1) {
      return _Orientation(normal: up, up: -normal, right: right);
    }
    if (dy == 1) {
      return _Orientation(normal: -up, up: normal, right: right);
    }
    throw ArgumentError('Nur direkte Nachbarflächen können gefaltet werden.');
  }

  @override
  bool operator ==(Object other) =>
      other is _Orientation &&
      other.normal == normal &&
      other.up == up &&
      other.right == right;

  @override
  int get hashCode => Object.hash(normal, up, right);
}
