import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/fall/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';

/// {@template fall_page}
/// One case, read rather than looked at.
///
/// Two states on one route: the question with its answers, and the reveal.
/// They are one screen because they are one act - you do not navigate away
/// from a question to be told whether you were right - and the reveal replaces
/// the answers rather than sitting under them, so the reader is never looking
/// at a verdict and a choice at the same time.
/// {@endtemplate}
class FallPage extends StatelessWidget {
  /// {@macro fall_page}
  const FallPage({required this.id, super.key});

  /// Which case. Comes from the route, so it can be anything.
  final String id;

  @override
  Widget build(BuildContext context) {
    final giCase = context.read<CaseSource>().caseOf(id);

    if (giCase == null) return const FallNotFound();

    return FallView(giCase: giCase);
  }
}

/// {@template fall_not_found}
/// A case id that is not a case.
///
/// Reachable from a deep link or from stale content, so it is a state rather
/// than an impossibility. One line, and the back gesture still works.
/// {@endtemplate}
class FallNotFound extends StatelessWidget {
  /// {@macro fall_not_found}
  const FallNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
          child: Text(
            context.l10n.caseNotFoundText,
            textAlign: TextAlign.center,
            style: GiText.subhead.copyWith(color: context.gi.labelSecondary),
          ),
        ),
      ),
    );
  }
}

/// {@template fall_view}
/// The case, in whichever of its two states it is in.
///
/// **The answer lives here and nowhere else, for now.** A reader's answers are
/// not persisted: Archiv marks a case as answered, and that needs a store the
/// backend seam does not have yet. When it does, this state moves behind
/// [CaseSource] and this widget stops holding it. Nothing else has to change.
/// {@endtemplate}
class FallView extends StatefulWidget {
  /// {@macro fall_view}
  const FallView({required this.giCase, super.key});

  /// The case being read.
  final GiCase giCase;

  @override
  State<FallView> createState() => _FallViewState();
}

class _FallViewState extends State<FallView> {
  String? _selectedOptionId;
  bool _revealed = false;

  void _select(String optionId) {
    if (_revealed) return;
    GiHaptics.selection(context);
    setState(() => _selectedOptionId = optionId);
  }

  void _confirm() {
    if (_selectedOptionId == null || _revealed) return;
    GiHaptics.reveal(context);
    setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // The image runs under the status bar and the top bar floats over it, so
      // the Scaffold must not subtract the inset first.
      top: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: _revealed
                ? FallReveal(
                    giCase: widget.giCase,
                    selectedOptionId: _selectedOptionId!,
                  )
                : FallQuestion(
                    giCase: widget.giCase,
                    selectedOptionId: _selectedOptionId,
                    onSelect: _select,
                    onConfirm: _confirm,
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // The date is dropped once the answers are gone: on the reveal the
            // reader is reading a recommendation, not placing a case in time.
            child: FallHeader(
              date: _revealed ? null : widget.giCase.date,
            ),
          ),
        ],
      ),
    );
  }
}
