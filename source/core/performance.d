import std.math : slow_cos = cos, slow_sin = sin;

version(LDC) {
	pragma(msg, "LDC compiler detected, using the fast stuff :)");
	pragma(LDC_intrinsic, "llvm.sqrt.f32")
		@nogc pure float sqrt(float);
} else {
	@nogc pure float sqrt(float f) {
		import std.math : sqrt;
		return sqrt(f);
	}
}
immutable float PI = 3.14159265359;

@nogc pure float cos(float v) { return slow_cos(v); }
@nogc pure float sin(float v) { return slow_sin(v); }