import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
	bool _showOriginal = false;
import '../../theme/app_icons.dart';
import '../../theme/typography_scale.dart';

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'painter_mask.dart';
import '../../services/auto_detect_service.dart';
import 'blur_pipeline.dart';
import '../../services/image_saver_service.dart';
import 'package:share_plus/share_plus.dart';
	bool _exportAsPng = false;
	int _exportQuality = 90;
	BlurType _blurType = BlurType.gaussian;
	int _blurStrength = 12;
	Future<void> _autoDetect() async {
		if (_imageBytes == null) return;
		setState(() => _loading = true);
		// TODO: Use actual model path
		final service = await AutoDetectService.create(modelPath: 'face_detection.tflite');
		final rects = await service.detect(_imageBytes!);
		for (final rect in rects) {
			_mask.addShape(rect, 8, MaskType.rectangle, false);
		}
		service.close();
		setState(() => _loading = false);
	}

class EditorScreen extends StatefulWidget {
	const EditorScreen({Key? key}) : super(key: key);

	@override
	State<EditorScreen> createState() => _EditorScreenState();
}

	Uint8List? _imageBytes;
	bool _loading = false;
	final _mask = PainterMask();
	double _brushSize = 24;
	bool _eraseMode = false;
	MaskType _shapeType = MaskType.rectangle;
	double _feather = 8;
	Rect? _pendingShape;

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
												? Column(
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
													)
												: Stack(
														alignment: Alignment.center,
														children: [
																					GestureDetector(
																						onLongPress: () => setState(() => _showOriginal = true),
																						onLongPressUp: () => setState(() => _showOriginal = false),
																						child: _showOriginal
																								? Image.memory(_imageBytes!, fit: BoxFit.contain, height: 320, color: Colors.grey.withOpacity(0.5), colorBlendMode: BlendMode.saturation)
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
															Positioned(
																bottom: 24,
																left: 24,
																right: 24,
																child: Column(
																	children: [
																		Row(
																			mainAxisAlignment: MainAxisAlignment.spaceEvenly,
																			children: [
																				IconButton(
																					icon: Icon(_eraseMode ? AppIcons.brush : Icons.remove),
																					tooltip: _eraseMode ? 'Brush' : 'Erase',
																					onPressed: () => setState(() => _eraseMode = !_eraseMode),
																				),
																				IconButton(
																					icon: const Icon(Icons.undo),
																					tooltip: 'Undo',
																					onPressed: () => setState(() => _mask.undo()),
																				),
																				IconButton(
																					icon: const Icon(Icons.clear),
																					tooltip: 'Clear',
																					onPressed: () => setState(() => _mask.clear()),
																				),
																				Expanded(
																					child: Slider(
																						min: 8,
																						max: 64,
																						value: _brushSize,
																						label: 'Brush Size',
																						onChanged: (v) => setState(() => _brushSize = v),
																					),
																				),
																			],
																		),
																		const SizedBox(height: 16),
																		Row(
																			mainAxisAlignment: MainAxisAlignment.spaceEvenly,
																			children: [
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
																					onChanged: (v) => setState(() => _blurType = v!),
																				),
																				Expanded(
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
																					onPressed: _applyBlur,
																				),
																			],
																		),
																	],
																),
															),
															Positioned(
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
																			icon: const Icon(Icons.auto_fix_high),
																			label: const Text('Auto-Detect'),
																			onPressed: _autoDetect,
																		),
																	],
																),
															),
														],
													),
							),
						);
					}

						void _applyBlur() {
							if (_imageBytes == null) return;
							setState(() {
								_imageBytes = BlurPipeline.applyBlur(_imageBytes!, _blurType, _blurStrength);
							});
						}

						Future<void> _exportImage() async {
							if (_imageBytes == null) return;
							setState(() => _loading = true);
							final path = await ImageSaverService.saveImage(_imageBytes!, asPng: _exportAsPng, quality: _exportQuality);
							setState(() => _loading = false);
							await Share.shareFiles([path], text: 'Blurred image');
						}

		class _MaskPainter extends CustomPainter {
			final PainterMask mask;
			_MaskPainter(this.mask);

			@override
			void paint(Canvas canvas, Size size) {
				for (final stroke in mask.strokes) {
					final paint = Paint()
						..color = stroke.erase ? Colors.transparent : Colors.blue.withOpacity(0.4)
						..strokeWidth = stroke.size
																		Positioned(
																			bottom: 0,
																			left: 0,
																			right: 0,
																			child: Container(
																				color: Colors.black.withOpacity(0.85),
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
																								icon: const Icon(Icons.share),
																								label: const Text('Export/Share'),
																								onPressed: () {
																									HapticFeedback.mediumImpact();
																									_exportImage();
																								},
																							),
																						],
																					),
																				),
																			),
																		),