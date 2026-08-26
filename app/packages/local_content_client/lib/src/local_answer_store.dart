import 'dart:convert';

import 'package:database_client/database_client.dart';
import 'package:flutter/foundation.dart';
import 'package:storage/storage.dart';

/// {@template local_answer_store}
/// Answers, kept on this device and nowhere else.
///
/// The local stand-in for [AnswerSource]. It writes one JSON blob through the
/// app's [Storage] interface, which is as much durability as a product with no
/// account can honestly offer. **Nothing here leaves the device**, which is
/// also the only reason it is allowed to exist before a backend does.
///
/// Reads are synchronous because a contact sheet asks about every visible cell
/// while it scrolls; the whole set is loaded once at startup and held in
/// memory.
/// {@endtemplate}
class LocalAnswerStore extends ChangeNotifier implements AnswerSource {
  /// {@macro local_answer_store}
  LocalAnswerStore({required Storage storage}) : _storage = storage;

  final Storage _storage;
  final Map<String, _LocalAnswer> _answers = {};

  /// Where the blob lives.
  static const String storageKey = 'gi_daily_answers_v1';

  /// Reads what is already on the device. Call once, before the first frame.
  ///
  /// A blob that cannot be parsed is discarded rather than thrown: a reader's
  /// quiz history is not worth a launch failure, and the shape may change
  /// while this is a stand-in.
  Future<void> load() async {
    try {
      final raw = await _storage.read(key: storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        _answers[entry.key] = _LocalAnswer.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    } on Object catch (_) {
      _answers.clear();
    }
  }

  @override
  GiAnswer? answerOf(String caseId) => _answers[caseId];

  @override
  int get answeredCount => _answers.length;

  @override
  Future<void> record(
    String caseId, {
    required String optionId,
    required bool isCorrect,
  }) async {
    // A case is answered once. See `AnswerSource.record`.
    if (_answers.containsKey(caseId)) return;

    _answers[caseId] = _LocalAnswer(
      optionId: optionId,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
    );
    notifyListeners();

    // The write is not awaited by the caller: the screen has already moved on
    // to the reveal, and a slow disk should not hold that up. A failed write
    // costs this device its history and nothing else.
    try {
      await _storage.write(
        key: storageKey,
        value: jsonEncode(
          _answers.map((key, value) => MapEntry(key, value.toJson())),
        ),
      );
    } on StorageException catch (_) {
      // Kept in memory for this session either way.
    }
  }
}

class _LocalAnswer implements GiAnswer {
  const _LocalAnswer({
    required this.optionId,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory _LocalAnswer.fromJson(Map<String, dynamic> json) => _LocalAnswer(
    optionId: json['optionId'] as String,
    isCorrect: json['isCorrect'] as bool,
    answeredAt: DateTime.parse(json['answeredAt'] as String),
  );

  @override
  final String optionId;

  @override
  final bool isCorrect;

  @override
  final DateTime answeredAt;

  Map<String, dynamic> toJson() => {
    'optionId': optionId,
    'isCorrect': isCorrect,
    'answeredAt': answeredAt.toIso8601String(),
  };
}
