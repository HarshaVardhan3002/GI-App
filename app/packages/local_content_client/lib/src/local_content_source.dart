import 'dart:convert';

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
      final imageMeta = <Map<String, dynamic>>[];

      for (final imageId in (post['imageIds'] as List).cast<String>()) {
        final image = imagesById[imageId];
        if (image == null) {
          throw StateError('post ${post['id']} references missing $imageId');
        }
        imageMeta.add(image);

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
          recommendation: recommendation,
          guideline: guideline,
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
class LocalCase {
  const LocalCase({
    required this.post,
    required this.raw,
    required this.images,
    required this.recommendation,
    required this.guideline,
  });

  /// The post as the existing feed expects it.
  final Post post;

  /// The original JSON, for the quiz and provenance the feed does not model.
  final Map<String, dynamic> raw;

  final List<Map<String, dynamic>> images;
  final Map<String, dynamic> recommendation;
  final Map<String, dynamic> guideline;

  /// The day this case is the case for.
  DateTime get date => post.createdAt;

  List<Map<String, dynamic>> get options =>
      (raw['options'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> get correctOption =>
      options.firstWhere((option) => option['correct'] == true);

  String get questionType => raw['questionType'] as String;

  String explanation(String languageCode) =>
      _localized(raw['explanation'] as Map<String, dynamic>, languageCode);

  String question(String languageCode) =>
      _localized(raw['question'] as Map<String, dynamic>, languageCode);

  /// True when any part of this case is standing in for the real thing.
  bool get isPlaceholder =>
      images.any(
        (image) =>
            (image['licence'] as Map<String, dynamic>)['spdx'] == 'PLACEHOLDER',
      ) ||
      (recommendation['quote'] as String).startsWith('PLATZHALTER');

  static String _localized(Map<String, dynamic> value, String languageCode) =>
      (languageCode == 'en' ? value['en'] : value['de']) as String;
}
