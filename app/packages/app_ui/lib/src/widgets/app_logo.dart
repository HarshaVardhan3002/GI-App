import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template app_logo}
/// The application wordmark.
///
/// *GI Daily*, set in Newsreader at 20/24, weight 400 - the first of the three
/// places this product uses a serif, alongside the question and the guideline
/// quote. See `DESIGN.md` section 5.
///
/// This replaced an SVG, and it keeps the SVG's sizing contract so that no call
/// site had to change. A vector scales to whatever box it is given; text does
/// not. So when a caller asks for a [width] or a [height], the wordmark is
/// scaled into that box with the requested [fit], exactly as the vector was.
/// When a caller asks for neither, it renders at its designed size instead of
/// being stretched to an arbitrary default.
/// {@endtemplate}
class AppLogo extends StatelessWidget {
  /// {@macro app_logo}
  const AppLogo({
    this.fit = BoxFit.contain,
    super.key,
    this.width,
    this.height,
    this.color,
  });

  /// How the wordmark is scaled when [width] or [height] is given.
  ///
  /// Ignored when both are null, because there is no box to fit into.
  final BoxFit fit;

  /// The width of the wordmark. Null renders it at its designed size.
  final double? width;

  /// The height of the wordmark. Null renders it at its designed size.
  final double? height;

  /// The colour of the wordmark. Defaults to the adaptive foreground.
  final Color? color;

  /// The wordmark, exactly as it is written. Never all-caps.
  static const String wordmark = 'GI Daily';

  @override
  Widget build(BuildContext context) {
    final text = Text(
      wordmark,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        // The font ships inside this package, so it is registered as
        // `packages/app_ui/Newsreader`. `package` adds that prefix. Without it
        // the family resolves to nothing and the wordmark is drawn in the
        // platform default - silently, because a missing font never fails a
        // build. Same reason `UITextStyle` passes it.
        package: 'app_ui',
        fontFamily: FontFamily.newsreader,
        // Newsreader carries an optical-size axis. Left at its default of 18 a
        // 20pt setting is drawn with slightly too much contrast, so `opsz` is
        // pinned to the rendered size.
        fontVariations: const [
          FontVariation('wght', 400),
          FontVariation('opsz', 20),
        ],
        fontSize: 20,
        height: 24 / 20,
        letterSpacing: -0.2,
        color: color ?? context.adaptiveColor,
      ),
    );

    if (width == null && height == null) return text;

    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(fit: fit, child: text),
    );
  }
}
