import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double kHandleWidth = 28;
const double kThemeButtonHeight = 56;

class DebugFloatingThemeButtonWrapper extends StatelessWidget {
  final Widget child;
  final bool debugShow;
  final AdaptiveThemeManager manager;

  const DebugFloatingThemeButtonWrapper({
    super.key,
    required this.debugShow,
    required this.manager,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.fromView(
      view: View.of(context),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DebugFloatingThemeButton(
          debugShow: debugShow,
          manager: manager,
          child: child,
        ),
      ),
    );
  }
}

/// A button that allows to change the theme on the fly. This is like a
/// floating chat bubble kind of button/s which can be moved around or clicked
/// show/hide itself at the right edge of the screen.
class DebugFloatingThemeButton extends StatefulWidget {
  /// The child widget to be rendered below this button. This ideally should
  /// be [MaterialApp] or the whole screen.
  final Widget child;

  /// Indicates whether to show floating theme mode switcher button or not.
  /// Default value is false. This is ignored in release mode.
  final bool debugShow;

  final AdaptiveThemeManager manager;

  /// Creates a [DebugFloatingThemeButton] widget.
  const DebugFloatingThemeButton({
    super.key,
    required this.child,
    required this.manager,
    this.debugShow = false,
  });

  @override
  State<DebugFloatingThemeButton> createState() =>
      _DebugFloatingThemeButtonState();
}

class _DebugFloatingThemeButtonState extends State<DebugFloatingThemeButton> {
  Offset position = Offset.zero;
  Offset initialLocalPosition = Offset.zero;
  Offset initialPosition = Offset.zero;

  bool animate = false;
  bool hidden = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (hidden) {
      final left = MediaQuery.of(context).size.width - kHandleWidth;
      position =
          Offset(left, position.dy == 0 ? kThemeButtonHeight : position.dy);
    }
  }

  void onTap() {
    animate = true;
    final width = MediaQuery.of(context).size.width;
    final left = !hidden ? width - kHandleWidth : width - 180;
    hidden = !hidden;
    setState(() => position = Offset(left, position.dy));
  }

  @override
  Widget build(BuildContext context) {
    // don't show in release mode
    if (kReleaseMode || !widget.debugShow) return widget.child;

    return MediaQuery.fromView(
      view: View.of(context),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: widget.manager.brightness == Brightness.light
              ? ThemeData.light()
              : ThemeData.dark(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              AnimatedPositioned(
                duration: Duration(milliseconds: animate ? 200 : 0),
                left: position.dx,
                top: position.dy,
                onEnd: () {
                  animate = false;
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: Builder(
                    builder: (context) {
                      return Container(
                        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                        height: kThemeButtonHeight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onPanUpdate: (details) {
                                final delta = details.localPosition -
                                    initialLocalPosition;
                                setState(() {
                                  hidden = false;
                                  position = Offset(
                                    (initialPosition.dx + delta.dx).clamp(
                                        0,
                                        MediaQuery.of(context).size.width -
                                            kHandleWidth),
                                    (initialPosition.dy + delta.dy).clamp(
                                        0,
                                        MediaQuery.of(context).size.height -
                                            kThemeButtonHeight),
                                  );
                                });
                              },
                              onPanStart: (details) {
                                initialLocalPosition = details.localPosition;
                                initialPosition = position;
                              },
                              onPanEnd: (details) {
                                initialLocalPosition = Offset.zero;
                                initialPosition = Offset.zero;
                              },
                              onTap: onTap,
                              child: SizedBox(
                                width: kHandleWidth,
                                height: double.infinity,
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ),
                            ToggleButtons(
                              borderRadius: BorderRadius.circular(6),
                              constraints: const BoxConstraints.tightFor(
                                  width: 40, height: 40),
                              onPressed: (index) {
                                final mode = AdaptiveThemeMode.values[index];
                                widget.manager.setThemeMode(mode);
                              },
                              isSelected: [
                                widget.manager.mode == AdaptiveThemeMode.light,
                                widget.manager.mode == AdaptiveThemeMode.dark,
                                widget.manager.mode == AdaptiveThemeMode.system,
                              ],
                              children: [
                                const Center(
                                  child: Icon(Icons.sunny, size: 18),
                                ),
                                Center(
                                  child: Transform.rotate(
                                    angle: pi * -30 / 180,
                                    child:
                                        const Icon(Icons.nightlight, size: 18),
                                  ),
                                ),
                                const Center(
                                  child: Icon(Icons.brightness_auto_outlined,
                                      size: 18),
                                )
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
