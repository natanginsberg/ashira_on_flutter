class Letter {
  late double from;
  late double to;
  late String letter;

  Letter();

  bool isIn(double position) {
    return from <= position && position <= to;
  }

  bool isPast(double position) {
    return from <= position;
  }

  bool isFuture(double position) {
    return from > position;
  }
}
