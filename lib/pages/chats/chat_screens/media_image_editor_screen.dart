import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/composer_media_item.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Full-screen image editor for a single staged composer image.
///
/// Supports: crop (free / 1:1 / 4:3 / 16:9 / 3:4 / 9:16 via the shared
/// image_cropper plugin), 90° rotation with reset, freehand drawing (brush
/// width + color palette incl. brand #2192CF), text overlays and emoji
/// stickers (move / resize / rotate / recolor / delete), plus unified
/// undo / redo / reset.
///
/// Everything (strokes, text, emoji) is painted by one [CustomPainter] inside
/// a [RepaintBoundary], so "Save" bakes a single high-res PNG via
/// `RenderRepaintBoundary.toImage`, exactly like the status editor. The
/// resulting file is handed back with `Get.back(result: File?)` so the
/// composer can swap it in for `ComposerMediaItem.file`.
class MediaImageEditorScreen extends StatefulWidget {
  final ComposerMediaItem item;

  const MediaImageEditorScreen({super.key, required this.item});

  @override
  State<MediaImageEditorScreen> createState() => _MediaImageEditorScreenState();
}

enum _EditorMode { move, draw, text, emoji }

class _MediaImageEditorScreenState extends State<MediaImageEditorScreen> {
  static const List<Color> _palette = [
    CustomColor.kWhite, // white
    CustomColor.kPrimaryColor, // brand
    CustomColor.kPrimaryDark, // brand dark
    CustomColor.kPrimaryMedium, // brand light
    CustomColor.kDangerRed,
    CustomColor.kGoldAccent,
    CustomColor.kSuccess,
    CustomColor.kInfo,
    CustomColor.kDarkSurface,
  ];

  static const List<String> _emojiSet = [
    '😀',
    '😁',
    '😂',
    '🤣',
    '😊',
    '😍',
    '😘',
    '😎',
    '🤩',
    '🥳',
    '😇',
    '🙂',
    '🤔',
    '😴',
    '🙄',
    '😬',
    '😅',
    '😭',
    '😢',
    '😡',
    '🥰',
    '😉',
    '😜',
    '🤗',
    '🤯',
    '👍',
    '👏',
    '🙌',
    '💪',
    '🤝',
    '✌️',
    '🤞',
    '🙏',
    '❤️',
    '💙',
    '🎉',
    '🔥',
    '🌟',
    '💯',
    '✨',
    '🚀',
    '🎂',
    '🍕',
    '☕',
    '⚡',
    '🌈',
    '🐦',
    '🦜',
  ];

  ui.Image? _image;
  String? _imageSourcePath;
  int _rotation = 0;

  final List<_Stroke> _strokes = [];
  final List<_TextSticker> _texts = [];
  final List<_EmojiSticker> _emojis = [];
  final List<_EditorSnapshot> _past = [];
  final List<_EditorSnapshot> _redo = [];

  _EditorMode _mode = _EditorMode.move;
  Color _brushColor = CustomColor.kPrimaryColor;
  double _brushWidth = 6;
  String? _selectedId;
  String? _drawingId;
  String? _editingTextId;
  bool _pushedThisEdit = false;

  final TextEditingController _textCtrl = TextEditingController();
  final GlobalKey _captureKey = GlobalKey();
  Size _viewSize = Size.zero;
  bool _loading = true;

  int _uid = 0;

  String get _newId => 'ed${_uid++}';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final img = await _decodeFile(widget.item.file.path);
      if (!mounted) return;
      setState(() {
        _image = img;
        _imageSourcePath = widget.item.file.path;
        _loading = false;
      });
    } catch (e) {
      debugPrint('media editor load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  static Future<ui.Image> _decodeFile(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _image?.dispose();
    super.dispose();
  }

  // ----- history -----

  _EditorSnapshot _snapshot() => _EditorSnapshot(
        rotation: _rotation,
        strokes: List.of(_strokes),
        texts: List.of(_texts),
        emojis: List.of(_emojis),
      );

  void _pushHistory() {
    _past.add(_snapshot());
    if (_past.length > 60) _past.removeAt(0);
    _redo.clear();
    _pushedThisEdit = true;
  }

  void _undo() {
    if (_past.isEmpty) return;
    _redo.add(_snapshot());
    _restore(_past.removeLast());
    setState(() {});
  }

  void _redoNow() {
    if (_redo.isEmpty) return;
    _past.add(_snapshot());
    _restore(_redo.removeLast());
    setState(() {});
  }

  void _pushHistoryOnce() {
    if (_pushedThisEdit) return;
    _pushHistory();
  }

  void _restore(_EditorSnapshot s) {
    _rotation = s.rotation;
    _strokes
      ..clear()
      ..addAll(s.strokes);
    _texts
      ..clear()
      ..addAll(s.texts);
    _emojis
      ..clear()
      ..addAll(s.emojis);
    if (_selectedId != null &&
        !_texts.any((t) => t.id == _selectedId) &&
        !_emojis.any((e) => e.id == _selectedId)) {
      _selectedId = null;
    }
    if (_editingTextId != null && !_texts.any((t) => t.id == _editingTextId)) {
      _editingTextId = null;
    }
    _drawingId = null;
  }

  void _resetAll() {
    _pushHistory();
    _strokes.clear();
    _texts.clear();
    _emojis.clear();
    _rotation = 0;
    _selectedId = null;
    _editingTextId = null;
    setState(() {});
  }

  // ----- overlay helpers -----

  _TextSticker? get _selectedText {
    for (final t in _texts) {
      if (t.id == _selectedId) return t;
    }
    return null;
  }

  _EmojiSticker? get _selectedEmoji {
    for (final e in _emojis) {
      if (e.id == _selectedId) return e;
    }
    return null;
  }

  Object? get _selectedOverlay {
    return _selectedText ?? _selectedEmoji;
  }

  void _selectById(String? id) {
    setState(() => _selectedId = id);
  }

  void _replaceText(_TextSticker old, _TextSticker newer) {
    final i = _texts.indexWhere((t) => t.id == old.id);
    if (i >= 0) _texts[i] = newer;
  }

  void _replaceEmoji(_EmojiSticker old, _EmojiSticker newer) {
    final i = _emojis.indexWhere((e) => e.id == old.id);
    if (i >= 0) _emojis[i] = newer;
  }

  Offset _toLocal(double fx, double fy) =>
      Offset(_viewSize.width * fx, _viewSize.height * fy);

  double _clampF(double v) => v.clamp(0.05, 0.95);

  _Stroke? _strokeById(String id) {
    for (final s in _strokes) {
      if (s.id == id) return s;
    }
    return null;
  }

  // ----- gestures -----

  void _onPanStart(DragStartDetails d) {
    if (_mode == _EditorMode.draw) {
      _drawingId = _newId;
      _pushHistory();
      _strokes.add(_Stroke(
        id: _drawingId!,
        points: [d.localPosition],
        color: _brushColor,
        width: _brushWidth,
      ));
      setState(() {});
      return;
    }
    if (_mode == _EditorMode.move) {
      final hit = _hitTest(d.localPosition);
      if (hit != null) {
        _pushHistory();
        _selectById(hit.id);
      } else {
        setState(() => _selectedId = null);
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final size = _viewSize;
    if (size.isEmpty) return;
    if (_mode == _EditorMode.draw && _drawingId != null) {
      final stroke = _strokeById(_drawingId!);
      if (stroke != null) {
        stroke.points.add(d.localPosition);
        setState(() {});
      }
      return;
    }
    if (_mode == _EditorMode.move) {
      final t = _selectedText;
      if (t != null) {
        _replaceText(
          t,
          t.copyWith(
            fx: _clampF(t.fx + d.delta.dx / size.width),
            fy: _clampF(t.fy + d.delta.dy / size.height),
          ),
        );
        setState(() {});
        return;
      }
      final e = _selectedEmoji;
      if (e != null) {
        _replaceEmoji(
          e,
          e.copyWith(
            fx: _clampF(e.fx + d.delta.dx / size.width),
            fy: _clampF(e.fy + d.delta.dy / size.height),
          ),
        );
        setState(() {});
      }
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_mode == _EditorMode.draw) {
      _drawingId = null;
      setState(() {});
    }
  }

  void _onPanCancel() {
    _drawingId = null;
    setState(() {});
  }

  void _onTapUp(TapUpDetails d) {
    if (_mode != _EditorMode.move) return;
    final hit = _hitTest(d.localPosition);
    if (hit != null) {
      _selectById(hit.id);
    } else {
      setState(() => _selectedId = null);
    }
  }

  _OverlayHit? _hitTest(Offset p) {
    final size = _viewSize;
    for (final e in _emojis.reversed) {
      final c = _toLocal(e.fx, e.fy);
      final r = _emojiFontSize(e) * 0.55;
      if ((p - c).distance <= r) return _OverlayHit(e.id, e);
    }
    for (final t in _texts.reversed) {
      final c = _toLocal(t.fx, t.fy);
      final r = _textFontSize(t) * 0.6;
      if ((p - c).distance <= r && !size.isEmpty) {
        return _OverlayHit(t.id, t);
      }
    }
    return null;
  }

  double _textFontSize(_TextSticker t) => 22 * t.size;
  double _emojiFontSize(_EmojiSticker e) => 44 * e.size;

  // ----- actions -----

  void _rotateImage() {
    _pushHistory();
    setState(() {
      _rotation = (_rotation + 1) % 4;
      _selectedId = null;
      _editingTextId = null;
    });
  }

  Future<void> _cropImage() async {
    if (_loading || _imageSourcePath == null) return;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: _imageSourcePath!,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: CustomColor.kPrimaryColor,
            toolbarWidgetColor: CustomColor.kTextOnDark,
            statusBarColor: CustomColor.kDarkSecondaryColor,
            backgroundColor: CustomColor.kBlack,
            activeControlsWidgetColor: CustomColor.kPrimaryColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio5x4,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
          ),
        ],
      );
      if (cropped == null) return;
      final img = await _decodeFile(cropped.path);
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = img;
        _imageSourcePath = cropped.path;
        _rotation = 0;
        _selectedId = null;
        _editingTextId = null;
      });
    } catch (e) {
      debugPrint('media editor crop error: $e');
      CustomSnackbar.show(
          title: 'Crop unavailable',
          message: 'Could not open the crop tool on this device.');
    }
  }

  void _addTextSticker() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _pushHistory();
    final sticker = _TextSticker(
      id: _newId,
      text: text,
      color: _brushColor,
      size: 1.0,
      rotationRad: 0,
      fx: 0.5,
      fy: 0.5,
    );
    setState(() {
      _texts.add(sticker);
      _selectedId = sticker.id;
      _editingTextId = sticker.id;
      _textCtrl.clear();
      _mode = _EditorMode.move;
    });
  }

  void _addEmojiSticker(String emoji) {
    _pushHistory();
    final sticker = _EmojiSticker(
      id: _newId,
      emoji: emoji,
      size: 1.0,
      rotationRad: 0,
      fx: 0.5,
      fy: 0.5,
    );
    setState(() {
      _mode = _EditorMode.move;
      _selectedId = sticker.id;
      _emojis.add(sticker);
    });
  }

  void _deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    _pushHistory();
    setState(() {
      _texts.removeWhere((t) => t.id == id);
      _emojis.removeWhere((e) => e.id == id);
      if (_editingTextId == id) _editingTextId = null;
      _selectedId = null;
      _textCtrl.clear();
    });
  }

  void _clearStrokes() {
    if (_strokes.isEmpty) return;
    _pushHistory();
    setState(() => _strokes.clear());
  }

  void _enterEditText(_TextSticker t) {
    _editingTextId = t.id;
    _textCtrl.text = t.text;
    _textCtrl.selection = TextSelection.collapsed(offset: t.text.length);
    setState(() {});
  }

  void _textFieldChanged(String value) {
    if (_editingTextId == null) {
      final t = _selectedText;
      if (t == null) return;
      _editingTextId = t.id;
      _pushHistory();
    }
    final t = _selectedText;
    if (t == null) return;
    _pushHistoryOnce();
    _replaceText(t, t.copyWith(text: value));
    setState(() {});
  }

  void _recolorSelected(Color color) {
    final t = _selectedText;
    if (t != null) {
      _pushHistoryOnce();
      _replaceText(t, t.copyWith(color: color));
      setState(() {});
      return;
    }
    _brushColor = color;
    setState(() {});
  }

  void _setMode(_EditorMode m) {
    setState(() {
      _mode = m;
      if (m == _EditorMode.text) {
        final t = _selectedText;
        if (t == null) _selectedId = null;
      } else {
        _selectedId = null;
      }
      _editingTextId = null;
      _drawingId = null;
      if (m != _EditorMode.text) _textCtrl.clear();
    });
  }

  Future<void> _export() async {
    if (_loading) return;
    final boundary = _captureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    try {
      final ui.Image img = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? bytes =
          await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final File out = File(
          '${dir.path}/hb_edited_${DateTime.now().microsecondsSinceEpoch}.png');
      await out.writeAsBytes(bytes.buffer.asUint8List());
      if (mounted) Get.back(result: out);
    } catch (e) {
      debugPrint('media editor export error: $e');
      CustomSnackbar.show(
          title: 'Could not save',
          message: 'Something went wrong while exporting the photo.');
    }
  }

  Future<void> _confirmClose() async {
    final dirty = _past.isNotEmpty ||
        _strokes.isNotEmpty ||
        _texts.isNotEmpty ||
        _emojis.isNotEmpty ||
        _rotation != 0;
    if (!dirty) {
      Get.back();
      return;
    }
    final discard = await Get.dialog<bool>(
      Dialog(
        backgroundColor: CustomColor.kDarkSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxxl.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46.w,
                height: 46.h,
                decoration: BoxDecoration(
                  color: CustomColor.kDangerRed.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_off_rounded,
                    color: CustomColor.kDangerRed, size: 24),
              ),
              SizedBox(height: 14.h),
              const Text(
                'Discard edits?',
                style: TextStyle(
                  color: CustomColor.kTextOnDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Your changes to this photo will be lost.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CustomColor.kTextOnDarkSecondary,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CustomColor.kTextOnDark,
                        side: const BorderSide(color: CustomColor.kDarkDivider),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('Keep editing'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Get.back(result: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: CustomColor.kDangerFill,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (discard == true && mounted) Get.back();
  }

  // ----- build -----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.kDarkSecondaryColor,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmClose();
          },
          child: Column(
            children: [
              _topBar(),
              Expanded(child: _previewArea()),
              _bottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final canUndo = _past.isNotEmpty;
    final canRedo = _redo.isNotEmpty;
    return Container(
      color: CustomColor.kDarkSurface2,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      child: Row(
        children: [
          _topIcon(Icons.close_rounded, tooltip: 'Close', onTap: _confirmClose),
          _topIcon(Icons.undo_rounded,
              tooltip: 'Undo', onTap: canUndo ? _undo : null),
          _topIcon(Icons.redo_rounded,
              tooltip: 'Redo', onTap: canRedo ? _redoNow : null),
          _topIcon(Icons.restart_alt_rounded,
              tooltip: 'Reset', onTap: canUndo ? _resetAll : null),
          Expanded(
            child: Center(
              child: Text(
                'Edit photo',
                style: TextStyle(
                  color: CustomColor.kTextOnDark,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _export,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: CustomColor.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.done_rounded,
                      color: CustomColor.kTextOnDark, size: 18.r),
                  SizedBox(width: 4.w),
                  Text(
                    'Save',
                    style: TextStyle(
                      color: CustomColor.kTextOnDark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topIcon(IconData icon,
      {required String tooltip, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        child: Container(
          padding: EdgeInsets.all(9.r),
          decoration: BoxDecoration(
            color: enabled ? CustomColor.kGlassColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
          ),
          child: Icon(
            icon,
            color: enabled
                ? CustomColor.kTextOnDark
                : CustomColor.kTextOnDarkMuted,
            size: 20.r,
          ),
        ),
      ),
    );
  }

  Widget _previewArea() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: CustomColor.kPrimaryColor),
      );
    }
    final image = _image;
    if (image == null) {
      return const Center(
        child: Text(
          'Could not load this image',
          style: TextStyle(color: CustomColor.kTextOnDarkMuted),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _viewSize = size;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                key: _captureKey,
                child: CustomPaint(
                  size: size,
                  painter: _EditorPainter(
                    image: image,
                    rotation: _rotation,
                    strokes: _strokes,
                    texts: _texts,
                    emojis: _emojis,
                    size: size,
                    fontSizeOfText: _textFontSize,
                    fontSizeOfEmoji: _emojiFontSize,
                    selectedId: _selectedId,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _onTapUp,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
              ),
              Positioned(
                left: 12.w,
                bottom: 12.h,
                child: _toolRail(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolRail() {
    return Container(
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        color: CustomColor.kBlack.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(color: CustomColor.kDarkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _railIcon(Icons.pan_tool_alt_outlined,
              mode: _EditorMode.move, onTap: () => _setMode(_EditorMode.move)),
          _railIcon(Icons.brush_rounded,
              mode: _EditorMode.draw, onTap: () => _setMode(_EditorMode.draw)),
          _railIcon(Icons.text_fields_rounded,
              mode: _EditorMode.text, onTap: () => _setMode(_EditorMode.text)),
          _railIcon(Icons.emoji_emotions_outlined,
              mode: _EditorMode.emoji,
              onTap: () => _setMode(_EditorMode.emoji)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Container(
                width: 28.w, height: 1, color: CustomColor.kDarkDivider),
          ),
          _railIcon(Icons.crop_rounded, onTap: _cropImage),
          _railIcon(Icons.rotate_90_degrees_cw_rounded, onTap: _rotateImage),
        ],
      ),
    );
  }

  Widget _railIcon(IconData icon,
      {_EditorMode? mode, required VoidCallback onTap}) {
    final active = mode != null && _mode == mode;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        child: Container(
          padding: EdgeInsets.all(9.r),
          decoration: BoxDecoration(
            color: active ? CustomColor.kPrimaryColor : CustomColor.kGlassColor,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
          ),
          child: Icon(icon,
              color: active
                  ? CustomColor.kTextOnDark
                  : CustomColor.kTextOnDarkSecondary,
              size: 19.r),
        ),
      ),
    );
  }

  Widget _bottomPanel() {
    switch (_mode) {
      case _EditorMode.draw:
        return _drawPanel();
      case _EditorMode.text:
        return _textPanel();
      case _EditorMode.emoji:
        return _emojiPanel();
      case _EditorMode.move:
        return _movePanel();
    }
  }

  Widget _panelShell({required String title, required Widget child}) {
    return Container(
      color: CustomColor.kDarkSurface2,
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: CustomColor.kTextOnDarkSecondary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 6.h),
          child,
        ],
      ),
    );
  }

  Widget _colorPalette(
      {required Color active, required ValueChanged<Color> onPick}) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      children: [
        for (final c in _palette)
          GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active == c
                      ? CustomColor.kPrimaryColor
                      : CustomColor.kDarkDivider,
                  width: active == c ? 2.5 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _drawPanel() {
    return _panelShell(
      title: 'DRAW',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.line_weight_rounded,
                  color: CustomColor.kTextOnDarkSecondary, size: 18.r),
              Expanded(
                child: Slider(
                  value: _brushWidth,
                  min: 2,
                  max: 18,
                  activeColor: CustomColor.kPrimaryColor,
                  onChanged: (v) => setState(() => _brushWidth = v),
                ),
              ),
              Text(
                '${_brushWidth.round()} px',
                style: TextStyle(
                    color: CustomColor.kTextOnDarkSecondary, fontSize: 11.sp),
              ),
              SizedBox(width: 10.w),
              TextButton(
                onPressed: _strokes.isEmpty ? null : _clearStrokes,
                child: const Text('Clear all'),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          _colorPalette(
            active: _brushColor,
            onPick: (c) => setState(() => _brushColor = c),
          ),
          SizedBox(height: 4.h),
          Text(
            'Draw on the photo with your finger.',
            style:
                TextStyle(color: CustomColor.kTextOnDarkMuted, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _textPanel() {
    final t = _selectedText;
    return _panelShell(
      title: t != null ? 'EDIT TEXT' : 'ADD TEXT',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  maxLength: 80,
                  maxLines: 1,
                  style: const TextStyle(
                      color: CustomColor.kTextOnDark, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: t != null
                        ? 'Tap a color to change it…'
                        : 'Type something…',
                    hintStyle: TextStyle(
                        color: CustomColor.kTextOnDarkMuted, fontSize: 14),
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: CustomColor.kDarkInputFill,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      borderSide:
                          const BorderSide(color: CustomColor.kDarkDivider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      borderSide:
                          const BorderSide(color: CustomColor.kPrimaryColor),
                    ),
                  ),
                  onTap: () {
                    if (t != null) _enterEditText(t);
                  },
                  onChanged: _textFieldChanged,
                ),
              ),
              SizedBox(width: 8.w),
              if (t != null)
                IconButton(
                  tooltip: 'Delete text',
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: CustomColor.kDangerRed),
                )
              else
                FilledButton(
                  onPressed:
                      _textCtrl.text.trim().isEmpty ? null : _addTextSticker,
                  style: FilledButton.styleFrom(
                    backgroundColor: CustomColor.kPrimaryFill,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Add'),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          _colorPalette(
            active: t?.color ?? _brushColor,
            onPick: (c) {
              if (t != null) {
                _recolorSelected(c);
              } else {
                setState(() => _brushColor = c);
              }
            },
          ),
          if (t != null) ...[
            SizedBox(height: 6.h),
            _overlaySliders(t),
          ],
          SizedBox(height: 4.h),
          Text(
            t != null
                ? 'Drag on the photo to move it. Sliders resize & rotate.'
                : 'Your text appears in the centre — drag it wherever you like.',
            style:
                TextStyle(color: CustomColor.kTextOnDarkMuted, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _overlaySliders(Object overlay) {
    final bool isText = overlay is _TextSticker;
    final _TextSticker? text = overlay as _TextSticker?;
    final _EmojiSticker? emoji = overlay as _EmojiSticker?;
    final double scale = isText ? text!.size : emoji!.size;
    final double rotDeg =
        (isText ? text!.rotationRad : emoji!.rotationRad) * 180 / math.pi;
    final double minScale =
        isText ? _TextSticker.minScale : _EmojiSticker.minScale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.zoom_in_rounded,
                color: CustomColor.kTextOnDarkSecondary, size: 16.r),
            Expanded(
              child: Slider(
                value: scale.clamp(minScale, 4.0),
                min: minScale,
                max: 4.0,
                activeColor: CustomColor.kPrimaryColor,
                onChangeStart: (_) => _pushHistory(),
                onChanged: (v) {
                  if (isText) {
                    _replaceText(text!, text.copyWith(size: v));
                  } else {
                    _replaceEmoji(emoji!, emoji.copyWith(size: v));
                  }
                  setState(() {});
                },
              ),
            ),
            Text(
              '${scale.toStringAsFixed(1)}×',
              style: TextStyle(
                  color: CustomColor.kTextOnDarkSecondary, fontSize: 11.sp),
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.rotate_right_rounded,
                color: CustomColor.kTextOnDarkSecondary, size: 16.r),
            Expanded(
              child: Slider(
                value: rotDeg,
                min: -180,
                max: 180,
                activeColor: CustomColor.kPrimaryColor,
                onChangeStart: (_) => _pushHistory(),
                onChanged: (v) {
                  final rad = v * math.pi / 180;
                  if (isText) {
                    _replaceText(text!, text.copyWith(rotationRad: rad));
                  } else {
                    _replaceEmoji(emoji!, emoji.copyWith(rotationRad: rad));
                  }
                  setState(() {});
                },
              ),
            ),
            Text(
              '${rotDeg.round()}°',
              style: TextStyle(
                  color: CustomColor.kTextOnDarkSecondary, fontSize: 11.sp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emojiPanel() {
    return _panelShell(
      title: 'EMOJI',
      child: SizedBox(
        height: 66.h,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 62,
            mainAxisExtent: 62,
          ),
          itemCount: _emojiSet.length,
          itemBuilder: (context, i) {
            return GestureDetector(
              onTap: () => _addEmojiSticker(_emojiSet[i]),
              child: Center(
                child: Text(_emojiSet[i], style: const TextStyle(fontSize: 30)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _movePanel() {
    final sel = _selectedOverlay;
    if (sel == null) {
      return _panelShell(
        title: 'MOVE / SELECT',
        child: Text(
          'Tap any text or emoji on the photo to select it, then drag to move it. '
          'Use Draw, Text and Emoji to add more.',
          style: TextStyle(
              color: CustomColor.kTextOnDarkMuted,
              fontSize: 12.sp,
              height: 1.4),
        ),
      );
    }
    final isText = sel is _TextSticker;
    return _panelShell(
      title: isText ? 'TEXT' : 'EMOJI',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _overlaySliders(sel),
          SizedBox(height: 6.h),
          Row(
            children: [
              if (isText) ...[
                OutlinedButton.icon(
                  onPressed: () => _enterEditText(sel),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CustomColor.kTextOnDark,
                    side: const BorderSide(color: CustomColor.kDarkDivider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg.r)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _colorPalette(
                    active: sel.color,
                    onPick: _recolorSelected,
                  ),
                ),
              ] else ...[
                const Spacer(),
                Text(
                  'Drag on the photo to move • Sliders resize & rotate',
                  style: TextStyle(
                      color: CustomColor.kTextOnDarkMuted, fontSize: 11.sp),
                ),
              ],
              SizedBox(width: 10.w),
              IconButton(
                tooltip: 'Delete',
                onPressed: _deleteSelected,
                style: IconButton.styleFrom(
                  backgroundColor:
                      CustomColor.kDangerRed.withValues(alpha: 0.16),
                ),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: CustomColor.kDangerRed, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorSnapshot {
  final int rotation;
  final List<_Stroke> strokes;
  final List<_TextSticker> texts;
  final List<_EmojiSticker> emojis;

  _EditorSnapshot({
    required this.rotation,
    required this.strokes,
    required this.texts,
    required this.emojis,
  });
}

class _OverlayHit {
  final String id;
  final Object overlay;

  _OverlayHit(this.id, this.overlay);
}

class _Stroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double width;

  _Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.width,
  });
}

class _TextSticker {
  final String id;
  final String text;
  final Color color;
  final double size;
  final double rotationRad;
  final double fx;
  final double fy;

  static const double minScale = 0.7;

  const _TextSticker({
    required this.id,
    required this.text,
    required this.color,
    required this.size,
    required this.rotationRad,
    required this.fx,
    required this.fy,
  });

  _TextSticker copyWith({
    String? text,
    Color? color,
    double? size,
    double? rotationRad,
    double? fx,
    double? fy,
  }) {
    return _TextSticker(
      id: id,
      text: text ?? this.text,
      color: color ?? this.color,
      size: size ?? this.size,
      rotationRad: rotationRad ?? this.rotationRad,
      fx: fx ?? this.fx,
      fy: fy ?? this.fy,
    );
  }
}

class _EmojiSticker {
  final String id;
  final String emoji;
  final double size;
  final double rotationRad;
  final double fx;
  final double fy;

  static const double minScale = 0.6;

  const _EmojiSticker({
    required this.id,
    required this.emoji,
    required this.size,
    required this.rotationRad,
    required this.fx,
    required this.fy,
  });

  _EmojiSticker copyWith({
    double? size,
    double? rotationRad,
    double? fx,
    double? fy,
  }) {
    return _EmojiSticker(
      id: id,
      emoji: emoji,
      size: size ?? this.size,
      rotationRad: rotationRad ?? this.rotationRad,
      fx: fx ?? this.fx,
      fy: fy ?? this.fy,
    );
  }
}

class _EditorPainter extends CustomPainter {
  final ui.Image image;
  final int rotation;
  final List<_Stroke> strokes;
  final List<_TextSticker> texts;
  final List<_EmojiSticker> emojis;
  final Size size;
  final double Function(_TextSticker) fontSizeOfText;
  final double Function(_EmojiSticker) fontSizeOfEmoji;
  final String? selectedId;

  _EditorPainter({
    required this.image,
    required this.rotation,
    required this.strokes,
    required this.texts,
    required this.emojis,
    required this.size,
    required this.fontSizeOfText,
    required this.fontSizeOfEmoji,
    required this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawImage(canvas);

    for (final s in strokes) {
      if (s.points.length < 2) continue;
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final t in texts) {
      final fontSize = fontSizeOfText(t);
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            color: t.color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(
                color: CustomColor.kOverlay40,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.85);
      final center = Offset(size.width * t.fx, size.height * t.fy);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(t.rotationRad);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
      if (t.id == selectedId) {
        final rect = Rect.fromCenter(
            center: center, width: tp.width + 12, height: tp.height + 8);
        _dashedBorder(canvas, rect);
      }
    }

    for (final e in emojis) {
      final fontSize = fontSizeOfEmoji(e);
      final tp = TextPainter(
        text: TextSpan(
          text: e.emoji,
          style: TextStyle(fontSize: fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final center = Offset(size.width * e.fx, size.height * e.fy);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(e.rotationRad);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
      if (e.id == selectedId) {
        final rect = Rect.fromCircle(
            center: center, radius: math.max(tp.width, tp.height) * 0.62);
        _dashedBorder(canvas, rect);
      }
    }
  }

  void _drawImage(Canvas canvas) {
    final w = size.width;
    final h = size.height;
    final effW = (rotation.isEven) ? w : h;
    final effH = (rotation.isEven) ? h : w;
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale = math.min(effW / iw, effH / ih);
    final dw = iw * scale;
    final dh = ih * scale;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(rotation * math.pi / 2);
    final Rect dest =
        Rect.fromCenter(center: Offset.zero, width: dw, height: dh);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, iw, ih),
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  void _dashedBorder(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = CustomColor.kPrimaryMedium
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      const double dash = 8;
      const double gap = 5;
      while (dist < metric.length) {
        final seg =
            metric.extractPath(dist, math.min(dist + dash, metric.length));
        canvas.drawPath(seg, paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EditorPainter oldDelegate) => true;
}
