import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:humming_bird/res/colors.dart';

/// Registry that lets the (already existing) deletion flow hand a frozen
/// picture of the last painted message bubble to the animation widget.
///
/// The controller captures the frame the moment deletion is accepted and
/// before it clears the message fields, so the dissolve always animates the
/// original text/media instead of an emptied bubble. It is intentionally
/// static and tiny: no sockets, no APIs, no model changes — only UI
/// coordination between the bubble and the delete animation.
class DeleteFrameCache {
  DeleteFrameCache._();

  static final Map<String, GlobalKey> _keys = {};
  static final Map<String, ui.Image> _images = {};

  /// Stable key for [messageId]. A bubble registers through its
  /// [MessageDeleteAnimation] wrapper while it is live on screen.
  static GlobalKey keyFor(String messageId) =>
      _keys.putIfAbsent(messageId, GlobalKey.new);

  /// Called by the animation widget when its tile leaves the tree.
  static void unregister(String messageId) {
    _keys.remove(messageId);
    _images.remove(messageId)?.dispose();
  }

  /// Best-effort freeze of the current painted bubble for [messageId].
  ///
  /// Waits up to one end-of-frame pass so a freshly laid out tile can be
  /// captured, then rasterises the existing repaint boundary. Returns false
  /// when the bubble is not on screen (nothing to animate) — callers keep the
  /// current immediate delete behaviour in that case.
  static Future<bool> capture(String messageId) async {
    if (_images.containsKey(messageId)) return true;
    final key = _keys[messageId];
    if (key == null || key.currentContext == null) return false;

    RenderRepaintBoundary? boundary;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (key.currentContext == null) return false;
      final renderObject = key.currentContext!.findRenderObject();
      if (renderObject is RenderRepaintBoundary &&
          !renderObject.debugNeedsPaint) {
        boundary = renderObject;
        break;
      }
      await WidgetsBinding.instance.endOfFrame;
    }
    if (boundary == null) return false;

    try {
      _images[messageId] = await boundary.toImage();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Moves the frozen frame out of the cache. The animation widget then owns
  /// it (and is responsible for calling [ui.Image.dispose]).
  static ui.Image? take(String messageId) => _images.remove(messageId);
}

enum _DeleteIntensity { soft, standard, media }

/// Humming Bird "magic disappearance" wrapper.
///
/// Replaces the old content -> deleted-placeholder AnimatedSwitcher inside the
/// bubble builders. While the message is alive it simply renders [content] (in
/// a [RepaintBoundary] so the deletion flow can freeze it). When [deleted] or
/// [removing] flips once, it plays a single dissolve (shrink -> blur -> fade ->
/// brand particles -> centre compression -> particle dissolve) and then either
/// shows the app's existing deleted placeholder or, for delete-for-me,
/// invokes [onRemoveComplete] so the existing controller removes the tile.
///
/// Safety: strictly one-shot per widget, never animates on initial build when
/// the message already arrived deleted, idempotent across duplicate socket
/// events, disposes its controller and image on unmount and never calls
/// setState after dispose.
class MessageDeleteAnimation extends StatefulWidget {
  const MessageDeleteAnimation({
    super.key,
    required this.messageId,
    required this.deleted,
    required this.removing,
    required this.content,
    required this.placeholder,
    this.messageType = '0',
    this.gentleRemoval = false,
    this.onRemoveComplete,
  });

  final String messageId;
  final bool deleted;
  final bool removing;
  final String messageType;

  /// When true the removal dissolve is calm (delete for me). Defaults to the
  /// full branded dissolve (delete for everyone / server deletions).
  final bool gentleRemoval;

  /// The existing, unmodified message content widget.
  final Widget content;

  /// The app's existing deleted-message placeholder.
  final Widget placeholder;

  /// Invoked once when a delete-for-me animation finishes, so the existing
  /// controller can remove the tile.
  final VoidCallback? onRemoveComplete;

  @override
  State<MessageDeleteAnimation> createState() => _MessageDeleteAnimationState();
}

class _MessageDeleteAnimationState extends State<MessageDeleteAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _blur;
  late _DeleteIntensity _intensity;
  late final List<_DeleteParticle> _particles;

  bool _removeMode = false;
  ui.Image? _image;
  bool _animating = false;
  bool _showPlaceholder = false;
  bool _removeDone = false;
  bool _firstEdgeSeen = false;

  bool get _isStandardMedia => widget.messageType != '0';

  @override
  void initState() {
    super.initState();
    _intensity = _initialIntensity();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _intensity == _DeleteIntensity.soft ? 460 : 540,
      ),
    );
    _buildAnimations();
    _particles = _generateParticles(widget.messageId);

    if (widget.deleted) {
      // Already-deleted messages (reloaded from storage, server tombstone
      // arriving while we were in another chat) render the placeholder right
      // away — no animation replay.
      _showPlaceholder = true;
    } else if (widget.removing) {
      _startDelete(removeMode: true);
    }

    _controller.addStatusListener(_onStatus);
  }

  _DeleteIntensity _initialIntensity() {
    if (widget.removing) return _removalIntensity();
    return _isStandardMedia
        ? _DeleteIntensity.media
        : _DeleteIntensity.standard;
  }

  /// "Delete for me" uses a calm fade; "delete for everyone" (and server
  /// deletions relayed to the receiver) use the full branded dissolve.
  _DeleteIntensity _removalIntensity() {
    if (widget.gentleRemoval) return _DeleteIntensity.soft;
    return _isStandardMedia
        ? _DeleteIntensity.media
        : _DeleteIntensity.standard;
  }

  @override
  void didUpdateWidget(MessageDeleteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_animating || _showPlaceholder || _firstEdgeSeen) return;

    final becameDeleted = !oldWidget.deleted && widget.deleted;
    final becameRemoving = !oldWidget.removing && widget.removing;
    if (!becameDeleted && !becameRemoving) return;
    _firstEdgeSeen = true;

    _startDelete(removeMode: becameRemoving && !becameDeleted);
  }

  void _startDelete({required bool removeMode}) {
    _removeMode = removeMode;
    _intensity = removeMode
        ? _removalIntensity()
        : (_isStandardMedia
            ? _DeleteIntensity.media
            : _DeleteIntensity.standard);
    _controller.duration = Duration(
      milliseconds: _intensity == _DeleteIntensity.soft ? 460 : 540,
    );
    _buildAnimations();
    _image = DeleteFrameCache.take(widget.messageId);
    _animating = true;
    _firstEdgeSeen = true;
    _controller.forward(from: 0);
  }

  void _buildAnimations() {
    final curve = Curves.easeInOutCubic;
    if (_intensity == _DeleteIntensity.soft) {
      _scale = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.97, end: 0.9), weight: 70),
      ]).animate(CurvedAnimation(parent: _controller, curve: curve));
      _opacity = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
      ]).animate(CurvedAnimation(parent: _controller, curve: curve));
      _blur = ConstantTween(0.0).animate(_controller);
    } else {
      final peak = _intensity == _DeleteIntensity.media ? 5.0 : 4.0;
      _scale = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.97, end: 0.9), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.82), weight: 40),
      ]).animate(CurvedAnimation(parent: _controller, curve: curve));
      _opacity = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 18),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 42),
        TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 40),
      ]).animate(CurvedAnimation(parent: _controller, curve: curve));
      _blur = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.0, end: peak), weight: 40),
        TweenSequenceItem(tween: Tween(begin: peak, end: 0.0), weight: 40),
      ]).animate(CurvedAnimation(parent: _controller, curve: curve));
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted) return;
    if (_removeDone || _showPlaceholder) return;

    if (_removeMode) {
      setState(() {
        _removeDone = true;
        _animating = false;
      });
      widget.onRemoveComplete?.call();
    } else {
      setState(() {
        _animating = false;
        _showPlaceholder = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _image?.dispose();
    _image = null;
    DeleteFrameCache.unregister(widget.messageId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showPlaceholder) return widget.placeholder;
    if (_removeDone) return const SizedBox.shrink();

    if (!_animating) {
      return RepaintBoundary(
        key: DeleteFrameCache.keyFor(widget.messageId),
        child: widget.content,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final Widget base = _image != null
            ? RawImage(
                image: _image,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              )
            : widget.content;

        final double sigma = _blur.value;
        return Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.passthrough,
          children: [
            Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: sigma > 0.05
                    ? ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: sigma,
                          sigmaY: sigma,
                        ),
                        child: base,
                      )
                    : base,
              ),
            ),
            if (_intensity != _DeleteIntensity.soft)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DeleteParticlePainter(
                      controller: _controller,
                      particles: _particles,
                      isMedia: _intensity == _DeleteIntensity.media,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<_DeleteParticle> _generateParticles(String messageId) {
    final random = math.Random(messageId.hashCode);
    final bool media = widget.messageType != '0';
    final int count =
        _intensity == _DeleteIntensity.soft ? 6 : (media ? 17 : 12);
    return List.generate(count, (i) {
      final double edge = random.nextDouble();
      final Offset origin;
      if (edge < 0.25) {
        origin = Offset(random.nextDouble(), 0);
      } else if (edge < 0.5) {
        origin = Offset(random.nextDouble(), 1);
      } else if (edge < 0.75) {
        origin = Offset(0, random.nextDouble());
      } else {
        origin = Offset(1, random.nextDouble());
      }
      final double angle = random.nextDouble() * 2 * math.pi;
      final double speed = 14 + random.nextDouble() * 22;
      final double size = media
          ? (5 + random.nextDouble() * 4)
          : (3 + random.nextDouble() * 2.5);
      final Color color = i.isEven
          ? Color.lerp(CustomColor.kPrimaryColor, CustomColor.kTextOnDark,
              0.1 + random.nextDouble() * 0.25)!
          : CustomColor.kPrimaryColor
              .withValues(alpha: 0.35 + 0.45 * random.nextDouble());
      return _DeleteParticle(
        origin: origin,
        angle: angle,
        speed: speed,
        size: size,
        rot: random.nextDouble() * math.pi,
        spin: (random.nextDouble() - 0.5) * 2.2,
        color: color,
        square: media ? i % 2 == 0 : i % 3 == 0,
      );
    });
  }
}

class _DeleteParticle {
  const _DeleteParticle({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.size,
    required this.rot,
    required this.spin,
    required this.color,
    required this.square,
  });

  final Offset origin;
  final double angle;
  final double speed;
  final double size;
  final double rot;
  final double spin;
  final Color color;
  final bool square;
}

class _DeleteParticlePainter extends CustomPainter {
  _DeleteParticlePainter({
    required this.controller,
    required this.particles,
    required this.isMedia,
  }) : super(repaint: controller);

  final AnimationController controller;
  final List<_DeleteParticle> particles;
  final bool isMedia;

  static const double _start = 0.30;
  static const double _span = 0.70;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = controller.value;
    if (t < _start || t >= 1.0) return;

    final double local = ((t - _start) / _span).clamp(0.0, 1.0);
    final double burst = Curves.easeOutCubic.transform(local);
    final Size box = Size(
      math.max(size.width, 4),
      math.max(size.height, 4),
    );

    for (final p in particles) {
      final double x = p.origin.dx * box.width;
      final double y = p.origin.dy * box.height;
      final double travel = p.speed * burst;
      final double px = x + math.cos(p.angle) * travel;
      final double py = y + math.sin(p.angle) * travel;
      final double fade = 1 - burst;
      final double s = p.size * (1 - burst * 0.7);

      final Color color = p.color.withValues(alpha: (0.9 * fade));
      final Paint paint = Paint()..color = color;

      if (p.square) {
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(p.rot + p.spin * burst);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(px, py), s * 0.35, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DeleteParticlePainter oldDelegate) =>
      oldDelegate.particles != particles || oldDelegate.isMedia != isMedia;
}
