import 'package:firebase_remote_config_repository/firebase_remote_config_repository.dart';
import 'package:notifications_repository/notifications_repository.dart';

/// Stands in for the Firebase-backed repositories the app shell expects.
///
/// Dart lets a class implement any other class, not only an interface, so these
/// satisfy `App`'s constructor without a Firebase project, a `google-services`
/// file, or a network round trip before the first frame.

/// Every feature flag is on.
///
/// Upstream this decides what the feed shows — sponsored blocks, recommended
/// posts. Here there is one case a day and nothing to gate, so the honest
/// answer is a constant rather than a config fetch that cannot happen.
class LocalRemoteConfigRepository implements FirebaseRemoteConfigRepository {
  const LocalRemoteConfigRepository();

  @override
  bool isFeatureAvailable(String key) => true;

  /// Callers `jsonDecode` this, so it has to be valid JSON rather than an
  /// empty string. An empty array means "no sponsored blocks", which is the
  /// truth: this product carries no advertising.
  @override
  String fetchRemoteData(String key) => '[]';

  @override
  Future<bool> activate() async => false;

  @override
  Future<bool> fetchAndActivate() async => false;

  @override
  Stream<RemoteConfigUpdate> onConfigUpdated() => const Stream.empty();

  @override
  Future<void> setConfigSetting(
    RemoteConfigSettings remoteConfigSettings,
  ) async {}
}

/// Push notifications, minus the push.
///
/// A daily habit product wants a notification eventually — that is the whole
/// retention mechanism. It needs a Firebase project and a server, neither of
/// which exists yet, so this returns no token rather than pretending to
/// register one.
class LocalNotificationsRepository implements NotificationsRepository {
  const LocalNotificationsRepository();

  @override
  Stream<String> onTokenRefresh() => const Stream.empty();

  @override
  Future<void> requestPermission() async {}

  @override
  Future<String?> fetchToken() async => null;
}
