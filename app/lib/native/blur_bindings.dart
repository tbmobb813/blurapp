import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

final class FfiBlur {
late final DynamicLibrary _lib;
late final _ApplyNative _apply;


FfiBlur() {
if (Platform.isAndroid) {
_lib = DynamicLibrary.open('libblurcore_jni.so');
} else if (Platform.isIOS) {
_lib = DynamicLibrary.process(); // symbol exported in iOS binary
} else {
throw UnsupportedError('Only mobile platforms supported');
}
_apply = _lib.lookupFunction<_ApplyC, _ApplyNative>('ios_blur_apply',
// On Android, rename the exported JNI symbol or export a C shim named `ios_blur_apply`
);
}


int apply(Pointer<Uint8> pixels, int w, int h, List<int> rects, int mode, int strength) {
final ptr = calloc<Int32>(rects.length);
for (var i=0;i<rects.length;i++) { ptr[i] = rects[i]; }
final res = _apply(pixels, w, h, ptr, rects.length ~/ 4, mode, strength);
calloc.free(ptr);
return res;
}
}


typedef _ApplyC = Int32 Function(Pointer<Uint8>, Int32, Int32, Pointer<Int32>, Int32, Int32, Int32);
typedef _ApplyNative = int Function(Pointer<Uint8>, int, int, Pointer<Int32>,