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
/// becomes the page."* Three passes missed that sentence in the same way, by
/// deciding the image's height first and letting whatever was left be somebody
/// else's problem. Each time the leftover turned up somewhere: between the
/// frame and the question, then at the foot of the card, then as most of the
/// lower half with the text pinned to its top.
///
/// **The text is measured and the image takes the rest.** That is the whole
/// inversion, and it is why there can be no empty region: the only thing that
/// can grow into spare space is the frame, and the frame always wants more.
/// A tall image gets nearly the whole screen; a short one is contained inside
/// the same field with [GiAmbient] lighting the margin it leaves. Nothing is
/// cropped either way, because the field contains rather than covers.
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

  /// Where the ambient light stops being at full strength, as a fraction of
  /// the card.
  ///
  /// **A constant, and named as one.** It used to be derived from the image
  /// field's height, which was knowable while the field was a fixed size.
  /// Now the field is whatever the text leaves, so its height is not known
  /// until the frame is laid out, and reading it back would cost a second
  /// pass to save nothing: the frame covers everything above the pane in every
  /// case, so the only ambient a reader ever sees is the band behind the pane
  /// and the margin beside a frame that does not fill the width. The grade's
  /// remaining job is to keep the foot of the screen darker than the head, so
  /// the tab bar sits on the ramp rather than on the image's light.
  static const double ambientFocusEnd = .68;


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

    return Stack(
      fit: StackFit.expand,
      children: [
        // The ground, lit by the frame it carries. Behind everything, the pane
        // included, which is the point of the pane being thin.
        GiAmbient(image: image, focusEnd: ambientFocusEnd),
        // **No scroll view here, on purpose.** An earlier pass put one in so an
        // enlarged text scale could not overflow, and it handed the Column
        // unbounded height, which contradicts the [Expanded] below and rendered
        // nothing at all. It was also solving a problem the Expanded already
        // solves: at a large text scale the block grows and the image field is
        // what yields. The card gives way at the image rather than at the
        // question, which is the right order for this screen.
        //
        // A second scrollable inside the vertical pager would also have taken
        // the drag off it.
        Column(
          children: [
            // **The frame takes everything the text does not.** Sizing the
            // field first and letting the leftover fall where it may is what
            // put an empty region on this card three passes running. Each
            // frame anchors to the top of this field at its own height and
            // dissolves at its own lower edge; what it does not want is the
            // ambient, lit by the same frame.
            Expanded(
              child: TageskarteImages(
                images: giCase.images,
                onIndexChanged: _onIndex,
              ),
            ),
            // Square-topped and edgeless: the frame above has already
            // dissolved into these pixels, so there is no boundary left to
            // draw. A rounded, highlighted top here was what made the pane read
            // as a card sitting on the screen instead of a surface the image
            // runs into.
            GiThinMaterial(
              radius: 0,
              showEdge: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: TageskarteText(giCase: giCase, imageIndex: index),
              ),
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
      ],
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
