import 'dart:convert';

import 'package:database_client/database_client.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

/// Reads the bundled content set and turns it into the models the existing app
/// already knows how to render.
///
/// The four JSON files under `assets/content/` are the database. Nothing here
/// talks to a network, so the app boots the same on a plane, in a basement, or
/// on a congress wifi that has given up.
///
/// Images become [MemoryImageMedia] rather than [ImageMedia]: the feed's media
/// carousel loads `ImageMedia` over the network, and our images live in the
/// bundle. Reading the bytes once at startup keeps every existing widget
/// working without touching it.
class LocalContentSource {
  LocalContentSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const _imagesAsset = 'assets/content/images.json';
  static const _guidelinesAsset = 'assets/content/guidelines.json';
  static const _recommendationsAsset = 'assets/content/recommendations.json';
  static const _postsAsset = 'assets/content/posts.json';

  /// The single author every case is posted by.
  ///
  /// The product has no social graph: there is one publisher, and it is the
  /// project. Modelling it as a user keeps the existing post header, which
  /// expects an author, working exactly as it does upstream.
  static const publisher = User(
    id: 'gi-daily-publisher',
    email: 'redaktion@gi-daily.example',
    username: 'GI Daily',
    fullName: 'GI Daily Redaktion',
    avatarUrl: '',
    isNewUser: false,
  );

  List<LocalCase> _cases = const [];
  bool _loaded = false;

  /// Every approved case, newest first.
  List<LocalCase> get cases => _cases;

  /// Reads and joins the content set. Safe to call more than once.
  Future<void> load() async {
    if (_loaded) return;

    final images = await _readList(_imagesAsset, 'images');
    final guidelines = await _readList(_guidelinesAsset, 'guidelines');
    final recommendations =
        await _readList(_recommendationsAsset, 'recommendations');
    final posts = await _readList(_postsAsset, 'posts');

    final imagesById = {
      for (final image in images) image['id'] as String: image,
    };
    final guidelinesById = {
      for (final guideline in guidelines) guideline['id'] as String: guideline,
    };
    final recommendationsById = {
      for (final recommendation in recommendations)
        recommendation['id'] as String: recommendation,
    };

    final built = <LocalCase>[];

    for (final post in posts) {
      // Constraint 3 lives here, and only here: the app renders approved
      // content and never sees a draft.
      final review = post['review'] as Map<String, dynamic>;
      if (review['status'] != 'approved') continue;

      final media = <Media>[];
      final imageMeta = <GiImage>[];

      for (final imageId in (post['imageIds'] as List).cast<String>()) {
        final image = imagesById[imageId];
        if (image == null) {
          throw StateError('post ${post['id']} references missing $imageId');
        }
        imageMeta.add(LocalImage(image));

        final bytes = await _bundle.load(image['assetPath'] as String);
        media.add(
          MemoryImageMedia(
            id: imageId,
            bytes: bytes.buffer.asUint8List(),
          ),
        );
      }

      final recommendation =
          recommendationsById[post['recommendationId'] as String];
      if (recommendation == null) {
        throw StateError(
          'post ${post['id']} references missing recommendation',
        );
      }
      final guideline = guidelinesById[recommendation['guidelineId'] as String];
      if (guideline == null) {
        throw StateError('recommendation references missing guideline');
      }

      built.add(
        LocalCase(
          post: Post(
            id: post['id'] as String,
            author: publisher,
            createdAt: DateTime.parse(post['date'] as String),
            caption: _caption(post),
            media: media,
          ),
          raw: post,
          images: imageMeta,
          recommendation: LocalRecommendation(recommendation),
          guideline: LocalGuideline(guideline),
        ),
      );
    }

    built.sort((a, b) => b.post.createdAt.compareTo(a.post.createdAt));
    _cases = List.unmodifiable(built);
    _loaded = true;
  }

  /// The caption shown under the image in the feed: the question itself.
  ///
  /// German only. The English strings in the content set exist so a developer
  /// can read what they are working on, and are never what a reader sees.
  static String _caption(Map<String, dynamic> post) {
    final question = post['question'] as Map<String, dynamic>;
    return question['de'] as String;
  }

  Future<List<Map<String, dynamic>>> _readList(
    String asset,
    String key,
  ) async {
    final raw = await _bundle.loadString(asset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (decoded[key]! as List).cast<Map<String, dynamic>>();
  }
}

/// One approved case, with everything it points at already resolved.
///
/// Implements [GiCase], so every screen above it talks to the seam rather than
/// to this class or to the JSON underneath it.
class LocalCase implements GiCase {
  const LocalCase({
    required this.post,
    required this.raw,
    required this.images,
    required this.recommendation,
    required this.guideline,
  });

  /// The post as the existing feed expects it.
  @override
  final Post post;

  /// The original JSON, for the quiz and provenance the feed does not model.
  final Map<String, dynamic> raw;

  @override
  final List<GiImage> images;

  @override
  final GiRecommendation recommendation;

  @override
  final GiGuideline guideline;

  /// The day this case is the case for.
  @override
  DateTime get date => post.createdAt;

  // `map<GiOption>` rather than a bare `map`: the tear-off infers
  // `List<_LocalOption>`, and the declared return type accepts it by
  // covariance while the *runtime* list stays the private one. Anything above
  // the seam that passes a `GiOption` callback to it - `firstWhere`'s
  // `orElse`, `fold`, `sort` - then fails at runtime with a type error about a
  // class it cannot see. **The seam has to hand out the interface type, not a
  // list that merely satisfies it.**
  @override
  List<GiOption> get options => (raw['options'] as List)
      .cast<Map<String, dynamic>>()
      .map<GiOption>(_LocalOption.new)
      .toList(growable: false);

  /// The one option marked correct. A case without exactly one is a content
  /// error, and it throws here rather than rendering a quiz with no answer.
  GiOption get correctOption =>
      options.firstWhere((option) => option.isCorrect);

  @override
  String get questionType => raw['questionType'] as String;

  @override
  String explanation(String languageCode) =>
      _localized(raw['explanation'] as Map<String, dynamic>, languageCode);

  @override
  String question(String languageCode) =>
      _localized(raw['question'] as Map<String, dynamic>, languageCode);

  /// True when any part of this case is standing in for the real thing.
  @override
  bool get isPlaceholder =>
      images.any((image) => image.isPlaceholder) ||
      recommendation.quote.startsWith('PLATZHALTER');

  static String _localized(Map<String, dynamic> value, String languageCode) =>
      (languageCode == 'en' ? value['en'] : value['de']) as String;
}

class _LocalOption implements GiOption {
  const _LocalOption(this._raw);

  final Map<String, dynamic> _raw;

  @override
  String get id => _raw['id'] as String;

  @override
  bool get isCorrect => _raw['correct'] == true;

  @override
  String text(String languageCode) => LocalCase._localized(
    _raw['text'] as Map<String, dynamic>,
    languageCode,
  );
}

class LocalImage implements GiImage {
  const LocalImage(this._raw);

  final Map<String, dynamic> _raw;

  Map<String, dynamic> get _licence => _raw['licence'] as Map<String, dynamic>;

  @override
  String get id => _raw['id'] as String;

  @override
  String get assetPath => _raw['assetPath'] as String;

  @override
  String get source => _raw['source'] as String;

  @override
  String get className => _raw['className'] as String;

  @override
  String get licenceSpdx => _licence['spdx'] as String;

  @override
  String get licenceHolder => _licence['holder'] as String;

  @override
  String get attributionText => _licence['attributionText'] as String;

  @override
  String get sourceUrl => _licence['sourceUrl'] as String;

  @override
  String get licenceUrl => _licence['licenceUrl'] as String;

  @override
  bool get isPlaceholder => licenceSpdx == 'PLACEHOLDER';
}

class LocalRecommendation implements GiRecommendation {
  const LocalRecommendation(this._raw);

  final Map<String, dynamic> _raw;

  @override
  String get number => _raw['number'] as String;

  @override
  String get strength => _raw['strength'] as String;

  @override
  String get consensus => _raw['consensus'] as String;

  // The one optional field on a recommendation: `GiRecommendation` says
  // "where the guideline gives one", and an Expertenkonsens gives none.
  // `platzhalter-r-6.12` omits it, and casting it as a required String threw
  // on the reveal of today's case. Empty means absent, and the screen draws no
  // row for it.
  //
  // Everything else here stays a hard cast on purpose. A recommendation with
  // no quote or no citation is a constraint-2 violation, and failing loudly is
  // the point.
  @override
  String get levelOfEvidence => (_raw['levelOfEvidence'] as String?) ?? '';

  @override
  String get quote => _raw['quote'] as String;

  @override
  String get citation => _raw['citation'] as String;

  @override
  String get url => _raw['url'] as String;
}

class LocalGuideline implements GiGuideline {
  const LocalGuideline(this._raw);

  final Map<String, dynamic> _raw;

  @override
  String get awmfRegisterNumber => _raw['awmfRegisterNumber'] as String;

  @override
  String get title => _raw['title'] as String;

  @override
  String get publisher => _raw['publisher'] as String;

  @override
  String get level => _raw['level'] as String;

  @override
  String get version => _raw['version'] as String;

  @override
  String get rightsNote => _raw['rightsNote'] as String;

  @override
  String get url => _raw['url'] as String;
}
