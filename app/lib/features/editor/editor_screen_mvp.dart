import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/color_utils.dart';
import '../../services/auto_detect_service.dart';
import '../../services/image_saver_service.dart';
import 'blur_engine_mvp.dart';
import 'mask_utils.dart';

/// MVP Editor Screen for Sprint 1
///
/// Core features:
/// - Image display and zoom/pan
/// - Brush tool for manual masking
/// - Blur type selection (Gaussian, Pixelate, Mosaic)
/// - Blur strength slider
/// - Real-time preview (throttled for performance)
/// - Export functionality
class EditorScreenMVP extends StatefulWidget {
  final Uint8List imageBytes;
  final String? sourcePath;

  const EditorScreenMVP({
    super.key,
    required this.imageBytes,
    this.sourcePath,
  });

  @override
  State<EditorScreenMVP> createState() => _EditorScreenMVPState();
}

class _EditorScreenMVPState extends State<EditorScreenMVP> {
  static const String _tag = 'EditorScreenMVP';

  // Image state
  ui.Image? _originalImage;
  ui.Image? _previewImage;

  // Editor state
  BlurType _selectedBlurType = BlurType.gaussian;
  double _blurStrength = 0.5;
  List<BrushStroke> _brushStrokes = [];
  bool _isProcessing = false;
  bool _isBrushMode = true;

  // Brush state
  double _brushSize = 50.0;
  final int _brushOpacity = 255;

  // Preview optimization
  static const int _previewWidth = 512;
  static const int _previewHeight = 512;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _originalImage?.dispose();
    _previewImage?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(widget.imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      setState(() {
        _originalImage = image;
      });

      debugPrint('$_tag: Loaded image ${image.width}x${image.height}');
      _updatePreview();
    } catch (e) {
      debugPrint('$_tag: Error loading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
      }
    }
  }

  Future<void> _updatePreview() async {
    if (_originalImage == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create mask from brush strokes
      final Uint8List mask = await BlurEngineMVP.createBrushMask(
        width: _previewWidth,
        height: _previewHeight,
        brushStrokes: _brushStrokes,
      );

      // Apply blur at preview resolution
      final Uint8List? resultBytes = await BlurEngineMVP.applyBlur(
        imageBytes: widget.imageBytes,
        mask: mask,
        blurType: _selectedBlurType,
        strength: _blurStrength,
        workingWidth: _previewWidth,
        workingHeight: _previewHeight,
      );

      if (resultBytes != null) {
        final ui.Codec codec = await ui.instantiateImageCodec(resultBytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image previewImage = frameInfo.image;

        setState(() {
          _previewImage?.dispose();
          _previewImage = previewImage;
        });
      }
    } catch (e) {
      debugPrint('$_tag: Error updating preview: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _exportImage() async {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting image...'),
              ],
            ),
          ),
        );
      }

      // Create full-resolution mask
      final Uint8List mask = await BlurEngineMVP.createBrushMask(
        width: _originalImage!.width,
        height: _originalImage!.height,
        brushStrokes: _brushStrokes.map((stroke) {
          // Scale brush strokes to full resolution
          final double scaleX = _originalImage!.width / _previewWidth;
          final double scaleY = _originalImage!.height / _previewHeight;

          return BrushStroke(
            points: stroke.points
                .map((point) => Point(
                      point.x * scaleX,
                      point.y * scaleY,
                    ))
                .toList(),
            size: stroke.size * ((scaleX + scaleY) / 2),
            opacity: stroke.opacity,
          );
        }).toList(),
      );

      // Apply blur at full resolution
      final Uint8List? resultBytes = await BlurEngineMVP.applyBlur(
        imageBytes: widget.imageBytes,
        mask: mask,
        blurType: _selectedBlurType,
        strength: _blurStrength,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }

      if (resultBytes != null) {
        // Save to device gallery
        final savedPath = await ImageSaverService.saveToGallery(
          resultBytes,
          filename: 'blurred_image_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          if (savedPath != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image saved to gallery successfully!'),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    // Could open gallery app here in future
                  },
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Failed to save image. Check gallery permissions.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to process image');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }
      debugPrint('$_tag: Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _onBrushPaintStart(Offset localPosition) {
    if (!_isBrushMode) return;

    setState(() {
      _brushStrokes.add(BrushStroke(
        points: [Point(localPosition.dx, localPosition.dy)],
        size: _brushSize,
        opacity: _brushOpacity,
      ));
    });
  }

  void _onBrushPaintUpdate(Offset localPosition) {
    if (!_isBrushMode || _brushStrokes.isEmpty) return;

    setState(() {
      final lastStroke = _brushStrokes.last;
      _brushStrokes[_brushStrokes.length - 1] = BrushStroke(
        points: [
          ...lastStroke.points,
          Point(localPosition.dx, localPosition.dy)
        ],
        size: lastStroke.size,
        opacity: lastStroke.opacity,
      );
    });
  }

  void _onBrushPaintEnd() {
    if (!_isBrushMode) return;

    // Throttle preview updates
    Future.delayed(const Duration(milliseconds: 100), _updatePreview);
  }

  void _clearMask() {
    setState(() {
      _brushStrokes.clear();
    });
    _updatePreview();
  }

  void _autoDetectFaces() async {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Prefer ML-based detection via AutoDetectService when available.
      final service = await AutoDetectService.create(
        modelPath: 'assets/models/face_detection_short_range.tflite',
      );

      final boxes = await service.detect(widget.imageBytes);

      if (boxes.isNotEmpty) {
        // Convert bounding boxes to brush strokes at preview resolution
        final List<BrushStroke> faceStrokes = [];

        for (final rect in boxes) {
          // Map rect center to preview coordinates
          final double centerX = (rect.left + rect.right) / 2.0;
          final double centerY = (rect.top + rect.bottom) / 2.0;

          // Scale to preview resolution
          final double scaleX = _previewWidth / _originalImage!.width;
          final double scaleY = _previewHeight / _originalImage!.height;

          faceStrokes.add(BrushStroke(
            points: [Point(centerX * scaleX, centerY * scaleY)],
            size:
                ((rect.width + rect.height) / 2.0) * ((scaleX + scaleY) / 2.0),
            opacity: 255,
          ));
        }

        setState(() {
          _brushStrokes = faceStrokes;
        });

        _updatePreview();
      }
    } catch (e) {
      debugPrint('$_tag: Face detection error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face detection failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _autoDetectSegmentation() async {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final service = await AutoDetectService.create(
        modelPath: 'assets/models/selfie_segmentation.tflite',
      );

      final Uint8List? maskBytes =
          await service.detectSegmentation(widget.imageBytes);

      if (maskBytes != null && maskBytes.isNotEmpty) {
        // Scale mask from original size to preview resolution
        final int srcW = _originalImage!.width;
        final int srcH = _originalImage!.height;
        final Uint8List scaled = scaleMaskNearestNeighbor(
            maskBytes, srcW, srcH, _previewWidth, _previewHeight);

        // Convert mask to brush strokes and apply
        final strokes = BlurEngineMVP.maskToBrushStrokes(
            scaled, _previewWidth, _previewHeight,
            stride: 8, threshold: 128, baseSize: 32.0);

        setState(() {
          _brushStrokes = strokes;
        });

        _updatePreview();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No segmentation result')),
          );
        }
      }
    } catch (e) {
      debugPrint('$_tag: Segmentation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Segmentation failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // ...existing code...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Blur Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isProcessing ? null : _exportImage,
          ),
        ],
      ),
      body: Column(
        children: [
          // Image display area
          Expanded(
            child: _buildImageDisplay(),
          ),

          // Controls
          Container(
            color: Colors.grey[900],
            child: Column(
              children: [
                _buildBlurControls(),
                _buildBrushControls(),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_originalImage == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onPanStart: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localPosition = box.globalToLocal(details.globalPosition);
        _onBrushPaintStart(localPosition);
      },
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localPosition = box.globalToLocal(details.globalPosition);
        _onBrushPaintUpdate(localPosition);
      },
      onPanEnd: (details) {
        _onBrushPaintEnd();
      },
      child: CustomPaint(
        painter: ImageDisplayPainter(
          originalImage: _originalImage!,
          previewImage: _previewImage,
          brushStrokes: _brushStrokes,
          brushSize: _brushSize,
          isProcessing: _isProcessing,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildBlurControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blur Type',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: BlurType.values.map((type) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(_getBlurTypeName(type)),
                    selected: _selectedBlurType == type,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedBlurType = type;
                        });
                        _updatePreview();
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Blur Strength',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _blurStrength,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(_blurStrength * 100).round()}%',
            onChanged: (value) {
              setState(() {
                _blurStrength = value;
              });
            },
            onChangeEnd: (value) {
              _updatePreview();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrushControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Brush Tool',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _isBrushMode,
                onChanged: (value) {
                  setState(() {
                    _isBrushMode = value;
                  });
                },
              ),
            ],
          ),
          if (_isBrushMode) ...[
            const SizedBox(height: 8),
            const Text(
              'Brush Size',
              style: TextStyle(color: Colors.white),
            ),
            Slider(
              value: _brushSize,
              min: 10.0,
              max: 100.0,
              divisions: 18,
              label: '${_brushSize.round()}px',
              onChanged: (value) {
                setState(() {
                  _brushSize = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.face),
              label: const Text('Auto Detect Faces'),
              onPressed: _isProcessing ? null : _autoDetectFaces,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_off),
              label: const Text('Auto Segment'),
              onPressed: _isProcessing ? null : _autoDetectSegmentation,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear Mask'),
              onPressed: _isProcessing ? null : _clearMask,
            ),
          ),
        ],
      ),
    );
  }

  String _getBlurTypeName(BlurType type) {
    switch (type) {
      case BlurType.gaussian:
        return 'Gaussian';
      case BlurType.pixelate:
        return 'Pixelate';
      case BlurType.mosaic:
        return 'Mosaic';
    }
  }
}

/// Custom painter for image display with brush overlay
class ImageDisplayPainter extends CustomPainter {
  final ui.Image originalImage;
  final ui.Image? previewImage;
  final List<BrushStroke> brushStrokes;
  final double brushSize;
  final bool isProcessing;

  ImageDisplayPainter({
    required this.originalImage,
    this.previewImage,
    required this.brushStrokes,
    required this.brushSize,
    required this.isProcessing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint imagePaint = Paint()..filterQuality = FilterQuality.medium;

    // Draw preview image if available, otherwise original
    final ui.Image imageToShow = previewImage ?? originalImage;

    // Calculate display rect to fit image in canvas
    final Rect imageRect = _calculateImageRect(imageToShow, size);
    canvas.drawImageRect(
      imageToShow,
      Rect.fromLTWH(
          0, 0, imageToShow.width.toDouble(), imageToShow.height.toDouble()),
      imageRect,
      imagePaint,
    );

    // Draw brush strokes overlay
    final Paint brushPaint = Paint()
      ..color = withOpacitySafe(Colors.red, 0.3)
      ..style = PaintingStyle.fill;

    for (final stroke in brushStrokes) {
      for (final point in stroke.points) {
        // Scale point to display coordinates
        final Offset displayPoint = Offset(
          imageRect.left +
              (point.x / _EditorScreenMVPState._previewWidth) * imageRect.width,
          imageRect.top +
              (point.y / _EditorScreenMVPState._previewHeight) *
                  imageRect.height,
        );

        canvas.drawCircle(
          displayPoint,
          stroke.size * 0.5, // Scale brush size for display
          brushPaint,
        );
      }
    }

    // Draw processing overlay
    if (isProcessing) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = withOpacitySafe(Colors.black, 0.5),
      );
    }
  }

  Rect _calculateImageRect(ui.Image image, Size canvasSize) {
    final double imageAspectRatio = image.width / image.height;
    final double canvasAspectRatio = canvasSize.width / canvasSize.height;

    double displayWidth, displayHeight;

    if (imageAspectRatio > canvasAspectRatio) {
      // Image is wider, fit to width
      displayWidth = canvasSize.width;
      displayHeight = canvasSize.width / imageAspectRatio;
    } else {
      // Image is taller, fit to height
      displayHeight = canvasSize.height;
      displayWidth = canvasSize.height * imageAspectRatio;
    }

    final double offsetX = (canvasSize.width - displayWidth) / 2;
    final double offsetY = (canvasSize.height - displayHeight) / 2;

    return Rect.fromLTWH(offsetX, offsetY, displayWidth, displayHeight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for real-time updates
  }
}
