import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/heute/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/media/media.dart';
import 'package:intl/intl.dart';

/// {@template tageskarte}
/// One case, one screen. **The image is the page.**
///
/// `DESIGN.md` section 8: *"Today's case fills the viewport and its lower edge
/// dissolves into the ground... there is no card: there is an image that
/// becomes the page."*
///
/// **The image is the whole screen, and everything else floats on it.** Four
/// passes read that sentence as "the image is the top part of the screen and
/// the text is the bottom part", and every one of them left an empty region
/// somewhere, because two boxes sharing a screen have to agree on a boundary
/// and a photograph does not have one. There is one box now. It is the
/// viewport, the frame fills it, and the question sits over the picture on a
/// pane of glass.
///
/// A frame that cannot fill the viewport without losing itself is centred and
/// the screen goes black above and below it. Those bars, and only those bars,
/// carry the image's own light: see [GiAmbient]. Nothing is ever drawn on the
/// picture.
/// {@endtemplate}
class Tageskarte extends StatefulWidget {
  /// {@macro tageskarte}
  const Tageskarte({required this.giCase, required this.isLast, super.key});

  /// The case this card is for.
  final GiCase giCase;

  /// Whether another case sits below this one. Drives the peek.
  final bool isLast;

  @override
  State<Tageskarte> createState() => _TageskarteState();
}

class _TageskarteState extends State<Tageskarte> {
  /// Which image the carousel is on.
  ///
  /// **It lives here rather than in the carousel** because two siblings report
  /// it: the dots in the text block, and the ambient light behind everything.
  /// The first pass left it at a hardcoded zero, so the carousel moved and the
  /// dots said it had not.
  int _imageIndex = 0;

  /// How much of the next card shows above the bottom bar.
  static const double peekHeight = 10;

  /// How far the glass pane takes to appear, in dp from its top edge.
  ///
  /// **A pane over a photograph cannot have a top edge.** Anywhere it starts is
  /// a horizontal line ruled across the picture, and the picture is the case.
  /// 96dp is roughly the height of the attribution and the metadata line, so
  /// the glass has reached full strength by the time the question needs it to
  /// be there.
  static const double paneFade = 96;

  @override
  Widget build(BuildContext context) {
    // The tab bar is a material and the card runs underneath it, so the bar no
    // longer shortens the body. The text block and the peek have to clear it
    // themselves, or they render behind the labels.
    //
    // **The bar's height is already in here.** With `extendBody`, a Scaffold
    // reports `max(bar height, viewPadding.bottom)` as the body's bottom
    // padding precisely so a full-bleed body can do this.
    final barInset = MediaQuery.paddingOf(context).bottom;
    final giCase = widget.giCase;
    final index = _imageIndex.clamp(0, giCase.images.length - 1);
    final image = giCase.images[index];

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Black, and lit only where the picture is not. When the frame
            // covers the screen none of this is visible at all; when it cannot,
            // this is what the bars are made of. Black rather than the app's
            // surface because a bar is the absence of a picture, not a surface
            // of the app.
            GiAmbient(
              image: image,
              ground: Colors.black,
              navInset: height <= 0 ? 0 : (barInset / height).clamp(0.0, .5),
            ),
            // **Full screen.** Not `Expanded`, not a fraction, not a box with
            // the text underneath it: the carousel is the viewport. Each frame
            // decides for itself whether it can survive covering it.
            TageskarteImages(
              images: giCase.images,
              onIndexChanged: _onIndex,
            ),
            // The reading end of the screen, floating on the picture. It is
            // measured, so it takes exactly the height its own text needs and
            // the picture keeps the rest.
            //
            // Square-topped, edgeless and dissolved in over [paneFade]: a
            // rounded, highlighted top would be a card sitting on a photograph,
            // and section 4 rule 3 is that there is no hairline where chrome
            // ends.
            //
            // The peek and the tab bar's inset are inside the pane rather than
            // below it, so the labels on the bar read off the same glass the
            // question does.
            Align(
              alignment: Alignment.bottomCenter,
              child: GiThinMaterial(
                radius: 0,
                showEdge: false,
                fadeExtent: paneFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The dissolve happens here, over nothing. Without this the
                    // fade ran across the attribution line, and the one string
                    // on the card that warns the reader what they are looking
                    // at was the one string sitting on clear glass over a
                    // photograph. Text starts where the material has arrived.
                    const SizedBox(height: paneFade),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: TageskarteText(giCase: giCase, imageIndex: index),
                    ),
                    if (!widget.isLast)
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.sm,
                          right: AppSpacing.sm,
                          bottom: barInset,
                        ),
                        child: const SizedBox(
                          height: peekHeight,
                          child: TageskartePeek(),
                        ),
                      )
                    else
                      SizedBox(height: barInset + peekHeight),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onIndex(int i) => setState(() => _imageIndex = i);
}

/// {@template tageskarte_text}
/// Everything under the image, as one block on a pane.
///
/// **It is measured, not capped.** The card is laid out around this block's
/// natural height, so every line it contains has to be bounded by its own
/// rules rather than by a fraction of the screen. The question is two lines
/// and the attribution is two; nothing here can run away.
///
/// The order is the mockup's: what the frame is, then which frame, then when
/// and what kind, then the question, then the way in.
/// {@endtemplate}
class TageskarteText extends StatelessWidget {
  /// {@macro tageskarte_text}
  const TageskarteText({required this.giCase, this.imageIndex = 0, super.key});

  /// The case being described.
  final GiCase giCase;

  /// Which image the carousel above is showing.
  final int imageIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final colors = context.gi;
    // The attribution belongs to the frame on screen, not to the first frame
    // of the set. A carousel whose images come from different datasets was
    // crediting all of them to whoever published image one.
    final image = giCase.images[imageIndex.clamp(0, giCase.images.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Directly under the frame, where the mockup puts it and where a
        // credit belongs: attached to the thing it credits, not filed at the
        // bottom of the card behind the next action.
        Text(
          image.attributionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GiText.footnote.copyWith(
            // Orange whenever the reader is owed a warning about what they are
            // looking at: a stand-in, or a real photograph whose rights are not
            // cleared. Both are things this app must never let pass as ordinary
            // content.
            color: giCase.isPlaceholder || !image.isRightsCleared
                ? colors.warning
                : colors.labelTertiary,
          ),
        ),
        const Gap.v(AppSpacing.sm),
        if (giCase.images.length > 1) ...[
          TageskarteDots(count: giCase.images.length, active: imageIndex),
          const Gap.v(AppSpacing.sm),
        ],
        Text(
          '${_formatDate(context, giCase.date)} · '
          '${_questionTypeLabel(l10n, giCase.questionType)}',
          style: GiText.caption.copyWith(color: colors.labelSecondary),
        ),
        const Gap.v(AppSpacing.xs),
        // **Truncated, not rolling.** `DESIGN.md` section 7 has always said
        // truncated, and the mockup shows two lines ending in an ellipsis. The
        // rolling line was added on the argument that a German clinical heading
        // does not fit on a phone and the reader should not have to open the
        // case to find out what it is about. On screen it did the opposite: at
        // any moment it showed the middle of a sentence, cut at both ends, so
        // the card's largest type was the one thing on it that could not be
        // read. A heading that has to be waited for is worse than a heading
        // that stops.
        //
        // The real fix is upstream and belongs to the content phase: the
        // `question` field in `posts.json` holds a whole clinical vignette
        // followed by the interrogative, and the card wants the interrogative.
        //
        // `GiRollingText` stays in `app_ui` per CLAUDE.md section 3.
        //
        // GiRollingText(
        //   giCase.question(languageCode),
        //   style: GiText.question.copyWith(color: colors.label),
        // ),
        Text(
          giCase.question(languageCode),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GiText.question.copyWith(color: colors.label),
        ),
        const Gap.v(AppSpacing.sm),
        FallOeffnen(postId: giCase.post.id),
      ],
    );
  }

  static String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d. MMMM', locale).format(date).toUpperCase();
  }

  static String _questionTypeLabel(AppLocalizations l10n, String type) =>
      switch (type) {
        'finding' => l10n.questionTypeFindingText,
        'diagnosis' => l10n.questionTypeDiagnosisText,
        'treatment' => l10n.questionTypeTreatmentText,
        // An unknown type is a content error, and printing it is how it gets
        // noticed rather than quietly rendering as nothing.
        _ => type.toUpperCase(),
      };
}
