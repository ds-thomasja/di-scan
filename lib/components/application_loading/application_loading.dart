import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// The full-screen "Application loading" state shown while a scan is being
/// prepared and opened.
///
/// Mirrors the Figma "Application loading" screen (node 5033:19060), composed
/// top to bottom of:
/// 1. an indeterminate DS progress circle ([DSProgressCircleFilled]) with the
///    scanner device illustration in its centre,
/// 2. a heading + subtext block,
/// 3. an optional info [DSInlineNotification] explaining a slow load
///    ([notification]),
/// 4. an optional [DSContainer] holding a 3-step [DSTimelineStepper]
///    ([timeline]),
/// 5. a tertiary "Cancel loading" [DSButton] wired to [onCancel].
///
/// The whole block is centred and scrolls when the available height is smaller
/// than its content, so the screen degrades gracefully on short viewports.
class ApplicationLoading extends StatelessWidget {
  /// Creates the "Application loading" screen.
  const ApplicationLoading({
    super.key,
    this.subline = 'This may take a few seconds',
    this.notification = true,
    this.timeline = true,
    this.onCancel,
  });

  /// The subtext shown under the "Loading scan..." heading. In the real flow
  /// this is switched between the elapsed-time copy described in this
  /// component's spec (e.g. "This only takes a moment" → "Ready in about 30
  /// seconds").
  final String subline;

  /// Whether the "Taking a little longer than usual" inline notification is
  /// shown. In the real flow this is switched on once the load exceeds the
  /// expected duration.
  final bool notification;

  /// Whether the timeline stepper card describing the loading phases is shown.
  final bool timeline;

  /// Called when the user presses "Cancel loading".
  ///
  /// The button stays enabled when this is null; pressing it is then a no-op.
  final VoidCallback? onCancel;

  /// The maximum width of the centred text/notification column, per Figma.
  static const double _contentMaxWidth = 512;

  /// The maximum width of the timeline stepper card, per Figma.
  static const double _timelineMaxWidth = 400;

  /// Height bound handed to [DSTimelineStepper] when this widget itself is laid
  /// out with an unbounded height. See [_buildContent] for why the stepper
  /// needs a bounded height at all.
  static const double _timelineFallbackMaxHeight = 1024;

  /// Duration and easing for the notification/timeline show-hide transition.
  /// [Curves.easeInOutSine] has no sharp acceleration at either end — of the
  /// standard easing curves it reads as the softest/gentlest, unlike the
  /// Figma spec's sharper cubic-bezier(0.4, 0.0, 0.2, 1). Duration is nudged
  /// up slightly from the spec's 200ms to 320ms so the softer curve has room
  /// to read as gentle rather than merely slow.
  static const Duration _transitionDuration = Duration(milliseconds: 320);
  static const Curve _transitionCurve = Curves.easeInOutSine;

  /// Fades and resizes [child] in/out instead of letting it appear/disappear
  /// with an instant height jump. Kept to a single fade+size pairing (no
  /// bounce, overshoot, or staggering) so the motion reads as a subtle easing
  /// of the layout rather than a standalone animation.
  ///
  /// [child] is wrapped in a [Center] before entering [SizeTransition]:
  /// `SizeTransition` always left-aligns its child on the cross axis when
  /// animating vertically (its `axisAlignment` only affects the main axis),
  /// so without it the notification/timeline content would hug the left
  /// edge instead of staying centred like the rest of the screen.
  static Widget _animatedSection({required bool visible, required Widget child}) {
    return AnimatedSwitcher(
      duration: _transitionDuration,
      switchInCurve: _transitionCurve,
      switchOutCurve: _transitionCurve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: Center(child: child)),
      ),
      child: visible ? child : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.border.radius.standard),
      child: ColoredBox(
        color: tokens.background.standard,
        // Centre the content while there is room for it, and fall back to
        // scrolling once the viewport gets shorter than the content.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.layout.m),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.hasBoundedHeight
                    ? constraints.maxHeight -
                        2 * tokens.spacing.layout.m
                    : 0,
              ),
              child: Center(
                child: _buildContent(
                  context,
                  tokens,
                  viewportHeight: constraints.hasBoundedHeight
                      ? constraints.maxHeight
                      : _timelineFallbackMaxHeight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DSTokensData tokens, {
    required double viewportHeight,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The DS "Progress circle filled": grey track, blue indeterminate arc
        // and the device illustration inside. The asset is pre-composed onto a
        // square canvas because the DS widget fits its image with
        // `BoxFit.cover` and documents that it "should be 396x396" — the
        // transparent padding reproduces the Figma inset of the device child.
        DSProgressCircleFilled.withImage(
          image: const AssetImage(
            'assets/images/primescan_device_progress_circle.png',
          ),
        ),
        SizedBox(height: tokens.spacing.layout.m),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: tokens.spacing.component.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Loading scan...',
                  textAlign: TextAlign.center,
                  style: tokens.text.heading3xl
                      .copyWith(color: tokens.text.standard),
                ),
                SizedBox(height: tokens.spacing.component.xs),
                _AnimatedSubline(
                  text: subline,
                  style: tokens.text.textBase
                      .copyWith(color: tokens.text.subdued),
                  maxWidth: _contentMaxWidth - 2 * tokens.spacing.component.l,
                ),
              ],
            ),
          ),
        ),
        _animatedSection(
          visible: notification,
          child: Column(
            key: const ValueKey('notification'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: tokens.spacing.layout.m),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.component.l),
                  child: DSInlineNotification(
                    notificationType: DSNotificationType.information,
                    title: 'Taking a little longer than usual',
                    message: 'This can take several minutes. Please stay on '
                        'this screen and do not refresh.',
                  ),
                ),
              ),
            ],
          ),
        ),
        _animatedSection(
          visible: timeline,
          child: Column(
            key: const ValueKey('timeline'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: tokens.spacing.layout.m),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _timelineMaxWidth),
                child: DSContainer(
                  padding: EdgeInsets.all(tokens.spacing.layout.m),
                  // DSTimelineStepper is a shrink-wrapping scroll view, which
                  // cannot be laid out with an unbounded height (its sliver
                  // geometry ends up with a NaN cache extent). The
                  // surrounding scroll view provides exactly that, so cap the
                  // stepper at the viewport height — well above the height of
                  // three collapsed steps, so it still shrink-wraps to its
                  // content.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: viewportHeight),
                    child: DSTimelineStepper(
                      // The steps are progress read-outs, not interactive
                      // disclosures: `enabled: false` stops them expanding
                      // while `isReadOnly: true` keeps the enabled
                      // (non-greyed) styling.
                      steps: [
                        DSTimelineStep(
                          type: DSTimelineStepType.active,
                          headline: 'Preparing workspace…',
                          enabled: false,
                          isReadOnly: true,
                        ),
                        DSTimelineStep(
                          type: DSTimelineStepType.future,
                          headline: 'Fetch scan data',
                          enabled: false,
                          isReadOnly: true,
                        ),
                        DSTimelineStep(
                          type: DSTimelineStepType.future,
                          headline: 'Start application',
                          enabled: false,
                          isReadOnly: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.layout.m),
        DSButton.tertiary(
          buttonText: 'Cancel loading',
          onPressed: () => onCancel?.call(),
        ),
      ],
    );
  }
}

/// Cross-fades [text] in place when it changes, only animating the
/// surrounding box's height if the incoming text wraps to a different number
/// of lines than the text it replaces. A same-line-count swap (e.g. one
/// elapsed-time string to another) stays at a fixed height and only fades;
/// a line-count change also resizes, matching [ApplicationLoading]'s other
/// show/hide transitions.
class _AnimatedSubline extends StatefulWidget {
  const _AnimatedSubline({
    required this.text,
    required this.style,
    required this.maxWidth,
  });

  final String text;
  final TextStyle style;
  final double maxWidth;

  @override
  State<_AnimatedSubline> createState() => _AnimatedSublineState();
}

class _AnimatedSublineState extends State<_AnimatedSubline> {
  bool _animateHeight = false;

  @override
  void didUpdateWidget(_AnimatedSubline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _animateHeight = _lineCount(oldWidget.text) != _lineCount(widget.text);
    }
  }

  int _lineCount(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: widget.maxWidth);
    final lineCount = painter.computeLineMetrics().length;
    painter.dispose();
    return lineCount;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: ApplicationLoading._transitionDuration,
      switchInCurve: ApplicationLoading._transitionCurve,
      switchOutCurve: ApplicationLoading._transitionCurve,
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        return _animateHeight
            ? SizeTransition(sizeFactor: animation, child: Center(child: fade))
            : fade;
      },
      child: Text(
        widget.text,
        key: ValueKey(widget.text),
        textAlign: TextAlign.center,
        style: widget.style,
      ),
    );
  }
}
