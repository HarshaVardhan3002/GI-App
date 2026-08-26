import 'package:flutter/foundation.dart';

/// {@template answer_source}
/// What the reader has answered, and how it got there.
///
/// A second seam beside `CaseSource`, and deliberately not part of it: cases
/// are content that arrives from a publisher, answers are this reader's own and
/// will belong to whatever account system exists later. Merging them would
/// mean a backend implementing one interface for two different things with two
/// different owners.
///
/// It is a [Listenable] so a screen can rebuild when an answer lands without
/// anything in between knowing where answers are kept.
/// {@endtemplate}
abstract interface class AnswerSource implements Listenable {
  /// What the reader answered for [caseId], or null if they have not.
  GiAnswer? answerOf(String caseId);

  /// Records an answer. Answering twice keeps the first: **a case is answered
  /// once.** The reveal is not a thing to retry until it is green, and Archiv
  /// would be lying if it were.
  Future<void> record(
    String caseId, {
    required String optionId,
    required bool isCorrect,
  });

  /// How many cases have been answered. Archiv's count.
  int get answeredCount;
}

/// {@template gi_answer}
/// One answer, as it was given.
/// {@endtemplate}
abstract interface class GiAnswer {
  /// Which option the reader chose.
  String get optionId;

  /// Whether that option was the correct one. Stored rather than recomputed:
  /// content is provisional and may be corrected after the fact, and a mark in
  /// Archiv should say what happened, not what would happen today.
  bool get isCorrect;

  /// When they answered.
  DateTime get answeredAt;
}
