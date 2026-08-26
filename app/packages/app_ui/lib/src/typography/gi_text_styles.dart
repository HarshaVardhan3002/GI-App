import 'package:app_ui/src/generated/fonts.gen.dart';
import 'package:flutter/widgets.dart';

/// {@template gi_text}
/// The eight type roles from `DESIGN.md` §5, and nothing else.
///
/// **The boundary is the whole discipline of the pairing.** Newsreader appears
/// at the two moments the reader stops and reads deliberately, plus the
/// identity: the wordmark, the question, the guideline quote. Fira Sans carries
/// everything scanned or operated. Mixing the faces outside that line is what
/// turns an editorial idea into decoration.
///
/// Sizes are not suggestions. The question is 26 because
/// `Argon-Plasma-Koagulation` measures 302px in Newsreader at 26 against a
/// 328px line on a 360dp phone, and 319px at 28. That is a margin at 26 and a
/// coincidence at 28.
/// {@endtemplate}
abstract final class GiText {
  static const String _package = 'app_ui';

  /// Newsreader carries an optical-size axis. Left at its default of 18, a 26pt
  /// setting is drawn with the contrast of a caption and looks thin and
  /// brittle, so `opsz` is pinned to the rendered size every time.
  static List<FontVariation> _newsreaderAxes(double size, double weight) => [
    FontVariation('wght', weight),
    FontVariation('opsz', size),
  ];

  static TextStyle _newsreader({
    required double size,
    required double height,
    double weight = 400,
    double letterSpacing = 0,
  }) => TextStyle(
    package: _package,
    fontFamily: FontFamily.newsreader,
    fontVariations: _newsreaderAxes(size, weight),
    fontSize: size,
    height: height / size,
    letterSpacing: letterSpacing,
  );

  static TextStyle _fira({
    required double size,
    required double height,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
  }) => TextStyle(
    package: _package,
    fontFamily: FontFamily.firaSans,
    fontWeight: weight,
    fontSize: size,
    height: height / size,
    letterSpacing: letterSpacing,
  );

  // ---------------------------------------------------------------------------
  // Newsreader: three uses, and no fourth.
  // ---------------------------------------------------------------------------

  /// The wordmark, in the app bar.
  static final TextStyle wordmark = _newsreader(
    size: 20,
    height: 24,
    letterSpacing: -.2,
  );

  /// The question. Capped at two lines wherever it appears on a card, which is
  /// what makes the collision arithmetic in `docs/SCREENS.md` decidable.
  static final TextStyle question = _newsreader(
    size: 26,
    height: 32,
    letterSpacing: -.5,
  );

  /// The guideline recommendation, quoted. Never more than 400 characters, and
  /// never without its citation in the same group.
  static final TextStyle quote = _newsreader(size: 17, height: 26);

  // ---------------------------------------------------------------------------
  // Fira Sans: everything that is scanned or operated.
  // ---------------------------------------------------------------------------

  /// Verdicts and group titles.
  static final TextStyle headline = _fira(
    size: 17,
    height: 22,
    weight: FontWeight.w600,
  );

  /// The explanation, and the answers.
  static final TextStyle body = _fira(size: 17, height: 24);

  /// Supporting text under a heading.
  static final TextStyle subhead = _fira(size: 15, height: 20);

  /// Attribution and citation lines.
  static final TextStyle footnote = _fira(size: 13, height: 18);

  /// Group headers and metadata. Uppercase at this size, which is why it
  /// carries tracking.
  static final TextStyle caption = _fira(
    size: 12,
    height: 16,
    weight: FontWeight.w500,
    letterSpacing: .4,
  );

  /// Counts, dates, AWMF register numbers and versions.
  ///
  /// Tabular figures, so columns line up and a citation never looks sloppy.
  static final TextStyle numeric = _fira(
    size: 13,
    height: 18,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
