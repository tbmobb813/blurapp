import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ffi/ffi.dart';
import '../../native/blur_bindings.dart';


class EditorScreen extends StatefulWidget { const EditorScreen({super.key});
@override State<EditorScreen> createState() => _EditorState(); }


class _EditorState extends State<EditorScreen> {
Uint8List? _rgba;
int _w=0, _h=0;
final _ffi = FfiBlur();
final _rects = <Rect>[];
int _mode = 1; // 0=blur,1=pixelate
int _strength = 12;


Future<void> _pick() async {
final x = await ImagePicker().pickImage(source: ImageSource.gallery);
if (x == null) return;
final img = await decodeImageFromList(await x.readAsBytes());
final recorder = PictureRecorder();
final canvas = Canvas(recorder);
canvas.drawImage(img, Offset.zero, Paint());
final pic = recorder.endRecording();
final uiImg = await pic.toImage(img.width, img.height);
final byteData = await uiImg.toByteData(format: ImageByteFormat.rawRgba);
setState(() {
_rgba = byteData!.buffer.asUint8List();
_w = uiImg.width; _h = uiImg.height; _rects.clear();
});
}


Future<void> _apply() async {
if (_rgba == null) return;
final ptr = malloc<Uint8>(_rgba!.length);
final bytes = ptr.asTypedList(_rgba!.length);
bytes.setAll(0, _rgba!);
final rectInts = <int>[];
for (final r in _rects) { rectInts.addAll([r.left.toInt(), r.top.toInt(), r.width.toInt(), r.height.toInt()]); }
_ffi.apply(ptr, _w, _h, rectInts, _mode, _strength);
setState(() { _rgba = bytes.toList().asUint8List(); });
malloc.free(ptr);
}


@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('BlurApp MVP')),
floatingActionButton: Column(
mainAxisSize: MainAxisSize.min,
children: [
FloatingActionButton.extended(onPressed: _pick, label: const Text('Pick')),
const SizedBox(height: 12),
FloatingActionButton.extended(onPressed: _apply, label: const Text('Apply')),
],
),
body: _rgba == null
? const Center(child: Text('Pick an image'))
: GestureDetector(
onPanStart: (d){ setState(()=> _rects.add(Rect.fromLTWH(d.localPosition.dx, d.localPosition.dy, 1, 1))); },
onPanUpdate: (d){ setState((){ final i=_rects.length-1; final r=_rects[i]; _rects[i]=Rect.fromLTRB(r.left, r.top, d.localPosition.dx, d.localPosition.dy); }); },
child: Stack(children:[
Positioned.fill(child: RawImage(image: Image.memory(_rgba!).image.resolve(const ImageConfiguration()).image)),
Positioned.fill(child: CustomPaint(painter: _RectsPainter(_rects)))
]),
),
);
}
}


class _RectsPainter extends CustomPainter {
final List<Rect> rects; _RectsPainter(this.rects);
@override void paint(Canvas c, Size s){ final p=Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=Colors.amber; for(final r in rects){ c.drawRect(r, p);} }
@override bool shouldRepaint(covariant _RectsPainter old)=> old.rects!=rects;
}