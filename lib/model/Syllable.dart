import 'Letter.dart';

class Syllable {
  late double from;
  late double to;
  late String text;
  late int tone;
  late List<Letter> letters;

  Syllable();

  bool isIn(double position) {
    return from <= position && position <= to;
  }

  bool isPast(double position){
    return from <= position;
  }
}
