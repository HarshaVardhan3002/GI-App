import 'package:chats_repository/chats_repository.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/app/app.dart';
import 'package:flutter_instagram_offline_first_clone/bootstrap_local.dart';
import 'package:local_content_client/local_content_client.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared/shared.dart';
import 'package:stories_repository/stories_repository.dart';
import 'package:user_repository/user_repository.dart';

/// The entrypoint this product ships from.
///
/// Same `App`, same router, same screens as upstream: the difference is
/// entirely in what is handed to them. `LocalDatabaseClient` replaces
/// `PowerSyncDatabaseClient`, `LocalAuthenticationClient` replaces the Supabase
/// one, and the two Firebase-backed repositories are satisfied by local stand-
/// ins. Nothing above the data layer knows or needs to.
///
/// Run it with:
///   flutter run -t lib/main_local.dart
void main() {
  bootstrapLocal(() async {
    // The content set is read once, before the first frame, so the feed never
    // renders an empty state it would have to recover from.
    final contentSource = LocalContentSource();
    await contentSource.load();

    final databaseClient = LocalDatabaseClient(source: contentSource);
    final authenticationClient = LocalAuthenticationClient();

    final userRepository = UserRepository(
      databaseClient: databaseClient,
      authenticationClient: authenticationClient,
    );

    // The case seam sits above the router rather than inside a screen, so any
    // route can read it and none of them knows it is backed by four JSON files.
    return RepositoryProvider<CaseSource>.value(
      value: databaseClient,
      child: App(
        userRepository: userRepository,
        postsRepository: PostsRepository(databaseClient: databaseClient),
        chatsRepository: ChatsRepository(databaseClient: databaseClient),
        storiesRepository: StoriesRepository(
          databaseClient: databaseClient,
          storage: const _NoStoriesStorage(),
        ),
        searchRepository: SearchRepository(databaseClient: databaseClient),
        notificationsRepository: const LocalNotificationsRepository(),
        firebaseRemoteConfigRepository: const LocalRemoteConfigRepository(),
        user: await userRepository.user.first,
      ),
    );
  });
}

/// Stories are not part of this product, so their storage never holds anything.
class _NoStoriesStorage implements StoriesStorage {
  const _NoStoriesStorage();

  @override
  Future<void> setUserStorySeen(Story story, String userId) async {}

  @override
  List<Story> mergeStories(
    List<Story> list1, {
    String? userId,
    List<Story>? list2,
  }) =>
      const [];
}
