import 'dart:async';
import 'dart:io';

import 'package:database_client/database_client.dart';
import 'package:flutter/foundation.dart';
import 'package:local_content_client/src/local_content_source.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

/// The whole app, backed by the bundled content set.
///
/// [DatabaseClient] is an interface, and `PowerSyncDatabaseClient` is just one
/// implementation of it. Swapping in this one means every existing screen —
/// the feed, the post layout, the navigation shell — keeps working with no
/// change to any of them, against JSON in the bundle instead of Postgres.
///
/// The interface covers a whole social network: follows, likers, chats,
/// stories, comments. This product has none of that. Those members return
/// empty rather than throwing, because the existing widgets call them while
/// building and an exception would take the feed down; the ones that would
/// *write* something throw, because silently accepting a write nobody stores
/// is worse than a stack trace.
class LocalDatabaseClient extends DatabaseClient {
  LocalDatabaseClient({required LocalContentSource source}) : _source = source;

  final LocalContentSource _source;

  /// Every approved case, newest first.
  List<LocalCase> get cases => _source.cases;

  /// Looks a case up by its post id, for screens that need the quiz and the
  /// provenance the feed's own models do not carry.
  LocalCase? caseOf(String postId) {
    for (final entry in _source.cases) {
      if (entry.post.id == postId) return entry;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Posts — the only part of this interface the product actually uses.
  // ---------------------------------------------------------------------------

  @override
  Future<List<Post>> getPage({
    required int offset,
    required int limit,
    bool onlyReels = false,
  }) async {
    // There are no reels. Returning empty keeps that tab honest rather than
    // filling it with the daily cases under a name they do not have.
    if (onlyReels) return const [];

    // One case per day, and you cannot read ahead: anything dated after today
    // stays out of the feed even when it is approved and sitting in the bundle.
    final today = DateTime.now();
    final published = _source.cases
        .where((entry) => !entry.date.isAfter(today))
        .toList(growable: false);

    if (offset >= published.length) return const [];
    return published
        .skip(offset)
        .take(limit)
        .map((entry) => entry.post)
        .toList(growable: false);
  }

  @override
  Future<Post?> getPostBy({required String id}) async => caseOf(id)?.post;

  @override
  Stream<List<Post>> postsOf({String? userId}) => Stream.value(
        _source.cases.map((entry) => entry.post).toList(growable: false),
      );

  @override
  Stream<int> postsAmountOf({required String userId}) =>
      Stream.value(_source.cases.length);

  // ---------------------------------------------------------------------------
  // Engagement — the product deliberately has none.
  //
  // No likes, no counts, no streaks. A daily case at Facharzt level is not
  // something to score, and a like button would be the first thing to make it
  // look like it was.
  // ---------------------------------------------------------------------------

  @override
  Future<List<User>> getPostLikers({
    required String postId,
    int limit = 30,
    int offset = 0,
  }) async =>
      const [];

  @override
  Future<List<User>> getPostLikersInFollowings({
    required String postId,
    int limit = 3,
    int offset = 0,
  }) async =>
      const [];

  @override
  Future<void> like({required String id, bool post = true}) async {}

  @override
  Stream<int> likesOf({required String id, bool post = true}) =>
      Stream.value(0);

  @override
  Stream<bool> isLiked({
    required String id,
    String? userId,
    bool post = true,
  }) =>
      Stream.value(false);

  // ---------------------------------------------------------------------------
  // Authoring — content arrives through the pipeline and a physician's
  // approval, never from inside the app.
  // ---------------------------------------------------------------------------

  @override
  Future<Post?> createPost({
    required String id,
    required String caption,
    required String media,
  }) async =>
      throw UnsupportedError('content is published by the pipeline');

  @override
  Future<String?> deletePost({required String id}) async =>
      throw UnsupportedError('content is published by the pipeline');

  @override
  Future<Post?> updatePost({required String id, String? caption}) async =>
      throw UnsupportedError('content is published by the pipeline');

  @override
  Future<void> sharePost({
    required String id,
    required User sender,
    required User receiver,
    required Message sharedPostMessage,
    Message? message,
    PostAuthor? postAuthor,
  }) async =>
      throw UnsupportedError('this build has no messaging');

  // ---------------------------------------------------------------------------
  // Comments — a clinical claim is not a comment thread. Reading returns
  // nothing; writing is refused.
  // ---------------------------------------------------------------------------

  @override
  Stream<int> commentsAmountOf({required String postId}) => Stream.value(0);

  @override
  Stream<List<Comment>> commentsOf({required String postId}) =>
      Stream.value(const []);

  @override
  Stream<List<Comment>> repliedCommentsOf({required String commentId}) =>
      Stream.value(const []);

  @override
  Future<void> createComment({
    required String content,
    required String postId,
    required String userId,
    String? repliedToCommentId,
  }) async =>
      throw UnsupportedError('this build has no comments');

  @override
  Future<void> deleteComment({required String id}) async =>
      throw UnsupportedError('this build has no comments');

  // ---------------------------------------------------------------------------
  // Users and the social graph — there is one publisher and one reader.
  // ---------------------------------------------------------------------------

  @override
  String? get currentUserId => LocalAuthenticationIds.reader;

  @override
  Stream<User> profile({required String id}) =>
      Stream.value(LocalContentSource.publisher);

  @override
  Future<void> updateUser({
    String? fullName,
    String? email,
    String? username,
    String? avatarUrl,
    String? pushToken,
  }) async {}

  @override
  Future<void> follow({required String followToId, String? followerId}) async {}

  @override
  Future<void> unfollow({
    required String unfollowId,
    String? unfollowerId,
  }) async {}

  @override
  Future<void> removeFollower({required String id}) async {}

  @override
  Future<bool> isFollowed({
    required String userId,
    String? followerId,
  }) async =>
      true;

  @override
  Stream<bool> followingStatus({
    required String userId,
    String? followerId,
  }) =>
      Stream.value(true);

  @override
  Stream<int> followersCountOf({required String userId}) => Stream.value(0);

  @override
  Stream<int> followingsCountOf({required String userId}) => Stream.value(0);

  @override
  Future<List<User>> getFollowers({String? userId}) async => const [];

  @override
  Future<List<User>> getFollowings({String? userId}) async => const [];

  @override
  Stream<List<User>> followers({required String userId}) =>
      Stream.value(const []);

  @override
  Future<List<User>> searchUsers({
    required int limit,
    required int offset,
    required String? query,
    String? userId,
    String? excludeUserIds,
  }) async =>
      const [];

  // ---------------------------------------------------------------------------
  // Chats and stories — not part of this product.
  // ---------------------------------------------------------------------------

  @override
  Stream<List<ChatInbox>> chatsOf({required String userId}) =>
      Stream.value(const []);

  @override
  Stream<List<Message>> messagesOf({required String chatId}) =>
      Stream.value(const []);

  @override
  Future<List<Message>> getMessages({
    required String chatId,
    required int limit,
    required int offset,
  }) async =>
      const [];

  @override
  Future<Message> getRepliedMessage({required String messageId}) async =>
      throw UnsupportedError('this build has no messaging');

  @override
  Future<void> sendMessage({
    required String chatId,
    required User sender,
    required User receiver,
    required Message message,
    PostAuthor? postAuthor,
  }) async =>
      throw UnsupportedError('this build has no messaging');

  @override
  Future<void> deleteMessage({required String messageId}) async =>
      throw UnsupportedError('this build has no messaging');

  @override
  Future<void> deleteChat({
    required String chatId,
    required String userId,
  }) async =>
      throw UnsupportedError('this build has no messaging');

  @override
  Future<void> createChat({
    required String userId,
    required String participantId,
  }) async =>
      throw UnsupportedError('this build has no messaging');

  @override
  Future<void> readMessage({required String messageId}) async {}

  @override
  Future<void> editMessage({
    required Message oldMessage,
    required Message newMessage,
  }) async =>
      throw UnsupportedError('this build has no messaging');

  @override
  RealtimeChannel onMessagesUpdates({
    required String conversationId,
    required ValueSetter<
            ({Map<String, dynamic> newRecord, Map<String, dynamic> oldRecord})>
        callback,
  }) =>
      throw UnsupportedError('this build has no realtime backend');

  @override
  Stream<List<Story>> getStories({
    required String userId,
    bool includeAuthor = true,
  }) =>
      Stream.value(const []);

  @override
  Future<void> createStory({
    required User author,
    required StoryContentType contentType,
    required String contentUrl,
    String? id,
    int? duration,
  }) async =>
      throw UnsupportedError('this build has no stories');

  @override
  Future<void> deleteStory({required String id}) async =>
      throw UnsupportedError('this build has no stories');

  @override
  Future<String> uploadStoryMedia({
    required String storyId,
    required File imageFile,
    required Uint8List imageBytes,
  }) async =>
      throw UnsupportedError('this build has no stories');
}

/// Ids shared between the local auth client and the local database client,
/// kept in one place so the two cannot drift apart.
abstract final class LocalAuthenticationIds {
  static const reader = 'gi-daily-reader';
}
