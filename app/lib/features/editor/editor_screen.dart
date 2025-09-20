import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auto_detect_service.dart';
import '../../services/image_saver_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/typography_scale.dart';
import 'blur_pipeline.dart';
import 'painter_mask.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  Uint8List? _imageBytes;
  bool _loading = false;
  final _mask = PainterMask();
  final double _brushSize = 24;
  bool _eraseMode = false;
  bool _showOriginal = false;
  bool _exportAsPng = false;
  int _exportQuality = 90;
  BlurType _blurType = BlurType.gaussian;
  int _blurStrength = 12;
  final double _feather = 8;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _loading = true);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _mask.clear();
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _autoDetectFaces() async {
    if (_imageBytes == null) return;
    setState(() => _loading = true);

    try {
      final service = await AutoDetectService.create(
          modelPath: 'assets/models/face_detection_short_range.tflite');

      final rects = await service.detect(_imageBytes!);
      for (final rect in rects) {
        _mask.addShape(rect, _feather, MaskType.rectangle, false);
      }

      service.close();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected ${rects.length} face(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face detection failed: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _autoDetectBackground() async {
    if (_imageBytes == null) return;
    setState(() => _loading = true);

    try {
      final service = await AutoDetectService.create(
          modelPath: 'assets/models/selfie_segmentation.tflite');

      final maskBytes = await service.detectSegmentation(_imageBytes!);
      if (maskBytes != null) {
        // Apply the segmentation mask to the PainterMask
        _mask.applySegmentationMask(maskBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Background detected successfully')),
          );
        }
      }

      service.close();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Background detection failed: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyBlur() {
    if (_imageBytes == null) return;
    setState(() {
      _imageBytes =
          BlurPipeline.applyBlur(_imageBytes!, _blurType, _blurStrength);
    });
  }

  Future<void> _exportImage() async {
    if (_imageBytes == null) return;
    setState(() => _loading = true);

    try {
      final path = await ImageSaverService.saveImage(_imageBytes!,
          asPng: _exportAsPng, quality: _exportQuality);
      await Share.shareXFiles([XFile(path)], text: 'Blurred image');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveImage() async {
    if (_imageBytes == null) return;
    setState(() => _loading = true);

    try {
      final path = await ImageSaverService.saveImagePermanent(_imageBytes!,
          asPng: _exportAsPng, quality: _exportQuality);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to: ${path.split('/').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blur Editor', style: TypographyScale.title),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _imageBytes == null
                ? _buildImagePicker()
                : _buildEditor(),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(AppIcons.blur, size: 64),
        const SizedBox(height: 24),
        const Text('Editor Placeholder', style: TypographyScale.headline),
        const SizedBox(height: 12),
        const Text('Import a photo to begin.', style: TypographyScale.body),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(AppIcons.gallery),
              label: const Text('Gallery'),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.camera),
              label: const Text('Camera'),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onLongPress: () => setState(() => _showOriginal = true),
          onLongPressUp: () => setState(() => _showOriginal = false),
          child: _showOriginal
              ? Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                  height: 320,
                  color: Colors.grey.withValues(alpha: 0.5),
                  colorBlendMode: BlendMode.saturation,
                )
              : Image.memory(_imageBytes!, fit: BoxFit.contain, height: 320),
        ),
        Positioned.fill(
          child: GestureDetector(
            onPanStart: (details) {
              _mask.startStroke(details.localPosition, _brushSize, _eraseMode);
            },
            onPanUpdate: (details) {
              _mask.addPoint(details.localPosition);
            },
            onPanEnd: (_) {
              _mask.endStroke();
            },
            child: AnimatedBuilder(
              animation: _mask,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MaskPainter(_mask),
                  child: Container(),
                );
              },
            ),
          ),
        ),
        _buildTopControls(),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 24,
      right: 24,
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Clear'),
            onPressed: () => setState(() => _imageBytes = null),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.face),
            label: const Text('Detect Faces'),
            onPressed: _autoDetectFaces,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_outline),
            label: const Text('Detect Background'),
            onPressed: _autoDetectBackground,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_eraseMode ? AppIcons.brush : Icons.remove),
                tooltip: _eraseMode ? 'Brush' : 'Erase',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _eraseMode = !_eraseMode);
                },
              ),
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _mask.undo());
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
                onPressed: () {
                  HapticFeedback.vibrate();
                  setState(() => _mask.clear());
                },
              ),
              DropdownButton<BlurType>(
                value: _blurType,
                items: const [
                  DropdownMenuItem(
                    value: BlurType.gaussian,
                    child: Text('Gaussian'),
                  ),
                  DropdownMenuItem(
                    value: BlurType.pixelate,
                    child: Text('Pixelate'),
                  ),
                  DropdownMenuItem(
                    value: BlurType.mosaic,
                    child: Text('Mosaic'),
                  ),
                ],
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _blurType = v!);
                },
              ),
              SizedBox(
                width: 120,
                child: Slider(
                  min: 1,
                  max: 32,
                  value: _blurStrength.toDouble(),
                  label: 'Strength',
                  onChanged: (v) => setState(() => _blurStrength = v.toInt()),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(AppIcons.blur),
                label: const Text('Apply Blur'),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  _applyBlur();
                },
              ),
              Switch(
                value: _exportAsPng,
                onChanged: (v) => setState(() => _exportAsPng = v),
              ),
              const Text('PNG'),
              SizedBox(
                width: 100,
                child: Slider(
                  min: 50,
                  max: 100,
                  value: _exportQuality.toDouble(),
                  label: 'Quality',
                  onChanged: (v) => setState(() => _exportQuality = v.toInt()),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _saveImage();
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _exportImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final PainterMask mask;

  _MaskPainter(this.mask);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in mask.strokes) {
      final paint = Paint()
        ..color = stroke.erase
            ? Colors.transparent
            : Colors.blue.withValues(alpha: 0.4)
        ..strokeWidth = stroke.size
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (stroke.points.isNotEmpty) {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
