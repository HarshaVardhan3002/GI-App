import 'dart:async';
import 'dart:developer';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/shared.dart';

/// Starts the app with no backend at all.
///
/// The upstream `bootstrap` initialises Firebase, opens a PowerSync database
/// and reads Supabase credentials out of the environment before the first
/// frame. This product has none of those: the content set ships in the bundle,
/// there are no accounts, and nothing is written anywhere. Keeping a separate
/// bootstrap rather than branching inside the original one means the upstream
/// path stays intact and re-mergeable.
///
/// What survives from upstream: the error handler, the bloc observer, hydrated
/// storage for bloc state, and the portrait lock.
Future<void> bootstrapLocal(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    logE(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const _AppBlocObserver();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(
          (await getTemporaryDirectory()).path,
        ),
      );

      SystemUiOverlayTheme.setPortraitOrientation();

      runApp(await builder());
    },
    (error, stackTrace) {
      logE(error.toString(), stackTrace: stackTrace);
    },
  );
}

class _AppBlocObserver extends BlocObserver {
  const _AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError ${bloc.runtimeType}', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
