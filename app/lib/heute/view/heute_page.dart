import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
// flutter_bloc re-exports provider's RepositoryProvider and `context.read`.
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/heute/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';

/// {@template heute_page}
/// Today, and the days before it. One case per screen, swiped vertically.
///
/// **The reader chooses to scroll.** There is no infinite feed underneath this,
/// no recommendation engine, and nothing loads while you are not looking. A
/// case ends and the next one begins, and when the cases run out the screen
/// says so.
/// {@endtemplate}
class HeutePage extends StatelessWidget {
  /// {@macro heute_page}
  const HeutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cases = context.read<CaseSource>().cases;

    if (cases.isEmpty) return const HeuteEmpty();

    return HeuteView(cases: cases);
  }
}

/// {@template heute_view}
/// The vertical pager.
///
/// A native [PageView] rather than a scroll view: paging is what makes each
/// case a whole screen instead of a card in a list, and it is what stops the
/// reader ever seeing two questions at once.
/// {@endtemplate}
class HeuteView extends StatefulWidget {
  /// {@macro heute_view}
  const HeuteView({required this.cases, super.key});

  /// Newest first. Today is the first page.
  final List<GiCase> cases;

  @override
  State<HeuteView> createState() => _HeuteViewState();
}

class _HeuteViewState extends State<HeuteView> {
  late final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: widget.cases.length,
          onPageChanged: (_) => GiHaptics.commit(context),
          itemBuilder: (context, index) => Tageskarte(
            key: ValueKey(widget.cases[index].post.id),
            giCase: widget.cases[index],
            isLast: index == widget.cases.length - 1,
          ),
        ),
        // The image runs full bleed to the top of the screen, so the wordmark
        // sits over it rather than in a bar above it. A scrim carries it,
        // because an endoscopic image can be bright at its top edge and white
        // text on it would be unreadable exactly when the image is best.
        //
        // Phase 8 replaces the scrim with the Normal material. The wordmark
        // does not move when it does.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HeuteHeader(),
        ),
      ],
    );
  }
}

/// {@template heute_empty}
/// What the reader sees when nothing has been released.
///
/// No illustration, no retry, no button. There is nothing for them to do, and
/// pretending otherwise would be the screen apologising. The tab bar stays, so
/// they are not stranded.
/// {@endtemplate}
class HeuteEmpty extends StatelessWidget {
  /// {@macro heute_empty}
  const HeuteEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
        child: Text(
          context.l10n.heuteEmptyText,
          textAlign: TextAlign.center,
          style: GiText.subhead.copyWith(color: context.gi.labelSecondary),
        ),
      ),
    );
  }
}
