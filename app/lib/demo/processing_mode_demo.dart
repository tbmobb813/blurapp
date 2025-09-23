import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';

import '../features/editor/blur_pipeline.dart';
import '../native/hybrid_blur_bindings.dart';

/// Demo widget showing hybrid processing capabilities
///
/// This demonstrates how your current UI can seamlessly integrate
/// both Dart fallback and future native MediaPipe processing.
class ProcessingModeDemo extends StatefulWidget {
  final Uint8List imageBytes;

  const ProcessingModeDemo({
    super.key,
    required this.imageBytes,
  });

  @override
  State<ProcessingModeDemo> createState() => _ProcessingModeDemoState();
}

class _ProcessingModeDemoState extends State<ProcessingModeDemo> {
  ProcessingModeInfo? _modeInfo;
  bool _isProcessing = false;
  Uint8List? _processedImage;
  String _lastProcessingMethod = '';

  @override
  void initState() {
    super.initState();
    _loadProcessingInfo();
  }

  Future<void> _loadProcessingInfo() async {
    final info = await HybridBlurPipeline.getProcessingModeInfo();
    if (!mounted) return;
    setState(() {
      _modeInfo = info;
    });
  }

  Future<void> _processWithCurrentMethod() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Use hybrid pipeline - automatically selects best method
      final result = await HybridBlurPipeline.processImage(
        widget.imageBytes,
        BlurType.gaussian,
        15,
        preferNative: true,
        isPreview: false,
      );
      if (!mounted) return;
      setState(() {
        _processedImage = result;
        _lastProcessingMethod = _modeInfo?.displayMode ?? 'Unknown';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processWithAutoSegmentation() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await HybridBlurPipeline.processWithAutoSegmentation(
        widget.imageBytes,
        20,
        isPreview: false,
      );
      if (!mounted) return;
      setState(() {
        _processedImage = result;
        _lastProcessingMethod = _modeInfo?.hasAutoSegmentation == true
            ? 'AI Segmentation'
            : 'Manual Fallback';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Segmentation error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Mode Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Processing Mode Information
            _buildModeInfoCard(),

            const SizedBox(height: 16),

            // Processing Controls
            _buildProcessingControls(),

            const SizedBox(height: 16),

            // Result Display
            Expanded(
              child: _buildResultDisplay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeInfoCard() {
    if (_modeInfo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading processing capabilities...'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processing Mode: ${_modeInfo!.displayMode}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Native Version: ${_modeInfo!.nativeVersion}'),
            const SizedBox(height: 8),
            _buildCapabilityChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityChips() {
    return Wrap(
      spacing: 8,
      children: [
        _buildCapabilityChip(
          'Native Support',
          _modeInfo!.hasNativeSupport,
          Icons.memory,
        ),
        _buildCapabilityChip(
          'Auto Segmentation',
          _modeInfo!.hasAutoSegmentation,
          Icons.auto_fix_high,
        ),
        _buildCapabilityChip(
          'GPU Acceleration',
          _modeInfo!.hasGpuAcceleration,
          Icons.speed,
        ),
        _buildCapabilityChip(
          'Privacy First',
          true, // Always true for this app
          Icons.privacy_tip,
        ),
      ],
    );
  }

  Widget _buildCapabilityChip(String label, bool available, IconData icon) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: available ? Colors.green : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: available ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
    backgroundColor: available
  ? withOpacitySafe(Colors.green, 0.1)
  : withOpacitySafe(Colors.grey, 0.1),
    );
  }

  Widget _buildProcessingControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Processing Methods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processWithCurrentMethod,
                    icon: const Icon(Icons.blur_on),
                    label: const Text('Standard Blur'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : _processWithAutoSegmentation,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Auto Segment'),
                  ),
                ),
              ],
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Processing image...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_lastProcessingMethod.isNotEmpty) ...[
                  const Spacer(),
                  Chip(
                    label: Text(
                      _lastProcessingMethod,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _processedImage != null
                  ? Image.memory(
                      _processedImage!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No processed image yet.\nTap a button above to test processing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
