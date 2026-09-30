import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// Which of the 3 Figma-defined "Application loading" screens to show.
///
/// The 3 states are mutually exclusive full-screen compositions, not
/// independent toggles — each one fixes its own title, subline presence,
/// notification content, and bottom-button label.
enum ApplicationLoadingState {
  /// The initial/countdown screen (Figma node 5033:19060): progress circle,
  /// title, a caller-driven elapsed-time subline, and the 3-step timeline.
  loading,

  /// The "taking longer than expected" screen (Figma node 5025:18764), shown
  /// once the load has been running for more than ~3 minutes: same progress
  /// circle and title, a fixed 2-line subline, and an info notification —
  /// no timeline.
  delayed,

  /// The backend-timeout screen (Figma node 5086:23421): a different title,
  /// no subline, no timeline, and a warning notification with a "Try again"
  /// link.
  timeout,
}

/// The full-screen "Application loading" state shown while a scan is being
/// prepared and opened.
///
/// Composed top to bottom of:
/// 1. an indeterminate DS progress circle ([DSProgressCircleFilled]) with the
///    scanner device illustration in its centre,
/// 2. a heading, and — only in [ApplicationLoadingState.loading]/
///    [ApplicationLoadingState.delayed] — a subtext,
/// 3. an optional [DSInlineNotification] (info in
///    [ApplicationLoadingState.delayed], warning with a "Try again" link in
///    [ApplicationLoadingState.timeout]),
/// 4. a [DSContainer] holding a 3-step [DSTimelineStepper], shown only in
///    [ApplicationLoadingState.loading],
/// 5. a tertiary [DSButton] ("Cancel"/"Close" depending on [state]) wired to
///    [onCancel].
///
/// The whole block is centred and scrolls when the available height is smaller
/// than its content, so the screen degrades gracefully on short viewports.
class ApplicationLoading extends StatelessWidget {
  /// Creates the "Application loading" screen.
  const ApplicationLoading({
    super.key,
    this.subline = 'Takes a few seconds',
    this.state = ApplicationLoadingState.loading,
    this.onCancel,
    this.onRetry,
  });

  /// The subtext shown under the "Preparing scan..." heading when [state] is
  /// [ApplicationLoadingState.loading]. In the real flow this is switched
  /// through the elapsed-time copy described in this component's spec (e.g.
  /// "Takes a few seconds" → "Takes under a minute"). Ignored for
  /// [ApplicationLoadingState.delayed] (fixed copy) and
  /// [ApplicationLoadingState.timeout] (no subline).
  final String subline;

  /// Which of the 3 Figma-defined screens to show. Defaults to the initial
  /// loading/countdown screen.
  final ApplicationLoadingState state;

  /// Called when the user presses the bottom button — labelled "Cancel" in
  /// [ApplicationLoadingState.loading]/[ApplicationLoadingState.delayed], or
  /// "Close" in [ApplicationLoadingState.timeout].
  ///
  /// The button stays enabled when this is null; pressing it is then a no-op.
  final VoidCallback? onCancel;

  /// Called when the user presses "Try again" in the
  /// [ApplicationLoadingState.timeout] notification; unused in the other two
  /// states. Per [DSNotificationAction], the link renders disabled when this
  /// is null.
  final VoidCallback? onRetry;

  /// The fixed 2-line subline shown in [ApplicationLoadingState.delayed],
  /// per Figma node 5025:18764. The line break is literal, not a wrap.
  static const String _delayedSubline =
      'Takes several minutes.\nThe delay is server-side, not on this device.';

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
    final isTimeout = state == ApplicationLoadingState.timeout;
    final showsNotification = state != ApplicationLoadingState.loading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The DS "Progress circle filled": grey track, blue indeterminate arc
        // and the device illustration inside, sourced from the canonical
        // "Primescan Generic Light" component (Figma node 5281:26689,
        // 2026-09-30). The asset is pre-composed onto a square canvas because
        // the DS widget fits its image with `BoxFit.cover` and documents that
        // it "should be 396x396" — the transparent padding reproduces the
        // Figma inset of the device child.
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
                  isTimeout ? "Couldn't prepare scan" : 'Preparing scan...',
                  textAlign: TextAlign.center,
                  style: tokens.text.heading3xl
                      .copyWith(color: tokens.text.standard),
                ),
                if (!isTimeout) ...[
                  SizedBox(height: tokens.spacing.component.xs),
                  _AnimatedSubline(
                    text: state == ApplicationLoadingState.delayed
                        ? _delayedSubline
                        : subline,
                    style: tokens.text.textBase
                        .copyWith(color: tokens.text.subdued),
                    maxWidth:
                        _contentMaxWidth - 2 * tokens.spacing.component.l,
                  ),
                ],
              ],
            ),
          ),
        ),
        _animatedSection(
          visible: showsNotification,
          child: Column(
            key: ValueKey('notification-${state.name}'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: tokens.spacing.layout.m),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.component.l),
                  child: isTimeout
                      ? DSInlineNotification(
                          notificationType: DSNotificationType.warning,
                          message:
                              'Server-side issue. Scan data remains safe.',
                          actions: [
                            DSNotificationAction(
                              title: 'Try again',
                              onTrigger: onRetry,
                            ),
                          ],
                        )
                      : DSInlineNotification(
                          notificationType: DSNotificationType.information,
                          message: 'Keep this screen open. Refreshing '
                              'restarts loading.',
                        ),
                ),
              ),
            ],
          ),
        ),
        _animatedSection(
          visible: state == ApplicationLoadingState.loading,
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
                          headline: 'Setting up workspace…',
                          enabled: false,
                          isReadOnly: true,
                        ),
                        DSTimelineStep(
                          type: DSTimelineStepType.future,
                          headline: 'Scan data',
                          enabled: false,
                          isReadOnly: true,
                        ),
                        DSTimelineStep(
                          type: DSTimelineStepType.future,
                          headline: 'Scanner',
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
          buttonText: isTimeout ? 'Close' : 'Cancel',
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
