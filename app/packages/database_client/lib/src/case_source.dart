import 'package:shared/shared.dart';

/// {@template case_source}
/// The seam for everything a case carries that a social feed's [Post] does not:
/// the question, its options, the explanation, and the provenance chain back to
/// a numbered guideline recommendation.
///
/// It sits beside `DatabaseClient` rather than on it, because it is this
/// product's own shape rather than a gap in the fork's. A backend arriving
/// later implements this interface; nothing above it needs to know where the
/// answers came from.
///
/// **Every string that a reader sees is language-keyed.** German is what the
/// product is; English exists so a developer can read what they are working on.
/// {@endtemplate}
abstract interface class CaseSource {
  /// Every case that may be shown, newest first.
  List<GiCase> get cases;

  /// The case behind a post, or null when the id is not one.
  GiCase? caseOf(String postId);
}

/// {@template gi_case}
/// One day's case: an image, a question, and a recommendation it traces to.
/// {@endtemplate}
abstract interface class GiCase {
  /// The post as the feed already understands it.
  Post get post;

  /// The day this case is the case for.
  DateTime get date;

  /// What the question asks about: a finding, a strategy, a classification.
  String get questionType;

  /// True when any part of this case stands in for the real thing.
  ///
  /// **A reader is owed this before anything else on the screen.** A
  /// placeholder image with a confident question beside it is worse than no
  /// case at all.
  bool get isPlaceholder;

  /// The question, in [languageCode].
  String question(String languageCode);

  /// Why the correct answer is correct, in [languageCode].
  String explanation(String languageCode);

  /// The four answers, in the order they are shown. Order is content, not
  /// presentation: it is fixed in the JSON so two readers see the same screen.
  List<GiOption> get options;

  /// The images, in carousel order.
  List<GiImage> get images;

  /// The recommendation this case traces to.
  GiRecommendation get recommendation;

  /// The guideline that recommendation belongs to.
  GiGuideline get guideline;
}

/// One answer.
abstract interface class GiOption {
  /// Stable within a case: `a`, `b`, `c`, `d`.
  String get id;

  /// The answer text, in [languageCode].
  String text(String languageCode);

  /// Exactly one option in a case has this.
  bool get isCorrect;
}

/// One image, with the attribution that has to render beside it.
abstract interface class GiImage {
  /// Stable id, used as the carousel key.
  String get id;

  /// Where in the bundle the bytes are.
  String get assetPath;

  /// The dataset this came from, or `placeholder`.
  String get source;

  /// The finding the dataset labelled it with.
  String get className;

  /// SPDX identifier, or `PLACEHOLDER`.
  ///
  /// Constraint 1: only open, de-identified CC BY 4.0 datasets, with
  /// attribution on screen. This is what says whether that is satisfied.
  String get licenceSpdx;

  /// Who holds the licence.
  String get licenceHolder;

  /// The line that renders under the image. Already written for display.
  String get attributionText;

  /// Where the image came from, for the provenance sheet.
  String get sourceUrl;

  /// The licence text itself.
  String get licenceUrl;

  /// True when this image is standing in for a real one.
  bool get isPlaceholder;
}

/// One numbered recommendation, quoted rather than reproduced.
abstract interface class GiRecommendation {
  /// The number as the guideline prints it, `6.12`.
  String get number;

  /// Empfehlungsgrad: `A`, `B`, `0`, or `EK` for a Expertenkonsens.
  String get strength;

  /// Konsensstärke, as the guideline states it.
  String get consensus;

  /// Level of evidence, where the guideline gives one.
  String get levelOfEvidence;

  /// The quote. **Constraint 2: at most 400 characters, always with
  /// [citation], never the full text.**
  String get quote;

  /// The full source line. Renders in the same group as [quote] so no later
  /// layout change can separate them.
  String get citation;

  /// Where the guideline lives. Leaves the app, and says so first.
  String get url;
}

/// The guideline a recommendation belongs to.
abstract interface class GiGuideline {
  /// AWMF register number.
  String get awmfRegisterNumber;

  /// The guideline's title.
  String get title;

  /// The author collective.
  String get publisher;

  /// S1, S2k, S3.
  String get level;

  /// Version as published.
  String get version;

  /// The rights position, in the guideline's own terms. Renders in full on the
  /// provenance sheet; it is not summarised anywhere.
  String get rightsNote;

  /// Where to read it.
  String get url;
}
