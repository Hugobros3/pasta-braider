import vector;
import performance;

@nogc Vec3f sampleSphere(Vec2f uv) {
	//const float sign = uv.x > 0.5 ? 1.0 : -1.0;
	const float uvx = (uv.x * 2.0) - 1.0;

	const float r = sqrt(1.0f - uvx * uvx);// * sign;
	const float phi = 2.0 * PI * uv.y;
	//return sampleHemisphere(uv);
	return Vec3f([cos(phi) * r, sin(phi) * r, uvx]);
}

@nogc Vec3f sampleHemisphere(Vec2f uv) {
	const float r = sqrt(1.0f - uv.x * uv.x);
	const float phi = 2.0 * PI * uv.y;
	return Vec3f([cos(phi) * r, sin(phi) * r, uv.x]);
}

/*import std.math : abs;
@nogc void ons(const ref Vec3f v1, ref Vec3f v2, ref Vec3f v3) {
if(abs(v1.x) > abs(v1.y)) {
float invLen = 1.0f / sqrt(v1.x * v1.x + v1.z * v1.z);
v2 = Vec3f([-v1.z * invLen, 0.0f, v1.x * invLen]);
v3 = v1 % v2;
v3.y = 0.0;
} else {
float invLen = 1.0f / sqrt(v1.y * v1.y + v1.z * v1.z);
v2 = Vec3f([0.0, v1.z * invLen, -v1.y * invLen]);
v3 = v1 % v2;
v3.x = 0.0;
}
}*/

@nogc Vec3f mapRectToCosineHemisphere(const Vec3f n, const Vec2f uv) {
	// create tnb:
	//http://jcgt.org/published/0006/01/01/paper.pdf
	float signZ = (n.z >= 0.0f) ? 1.0f : -1.0f;
	float a = -1.0f / (signZ + n.z);
	float b = n.x * n.y * a;
	Vec3f b1 = Vec3f([1.0f + signZ * n.x * n.x * a, signZ*b, -signZ * n.x]);
	Vec3f b2 = Vec3f([b, signZ + n.y * n.y * a, -n.y]);

	// remap uv to cosine distributed points on the hemisphere around n
	float phi = 2.0f * 3.141592 * uv.x;
	float cosTheta = sqrt(uv.y);
	float sinTheta = sqrt(1.0f - uv.y);
	return ((b1 * cos(phi) + b2 * sin(phi)) * cosTheta + n * sinTheta).normalize();
}