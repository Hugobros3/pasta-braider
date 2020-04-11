import vector;
import performance;
import film;
import color;
import camera;
import ray;
import scene;
import material;

import window;

import std.random;
import std.stdio;

/*@nogc Vec3f hemisphere(Vec2f uv) {
	const float r = sqrt(1.0f - uv.x * uv.x);
	const float phi = 2.0 * PI * uv.y;
	return Vec3f([cos(phi) * r, sin(phi) * r, uv.x]);
}

import std.math : abs;
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

@nogc float uniform_rng() {
	float val = (float(rng.front) * (1.0f / ((uint.max))));
	rng.popFront();
	return val;
}

auto make_pt_renderer(ColorSpace, PrimitiveType)() {
	return function RGB(immutable ref Camera camera, const Vec2i viewportSize, Vec2i pos, const ref Scene!(PrimitiveType) scene) @nogc { 
		Vec3f color = [ 0.0, 0.0, 0.0 ];

		Ray ray = generateRay(camera, viewportSize, Vec2f([pos.x + uniform_rng(), pos.y + uniform_rng()]));

		int depth = 0;
		Vec3f cost = 1.0;
		while(true) {
			// TODO: proper russian roulette
			if(depth > 25)
				break;
			
			Hit hit = scene.intersect(ray);

			if(hit.primId != -1) {
				Vec3f hitPoint = ray.origin + ray.direction * hit.t;
				Vec3f hitNormal = scene.primitives[hit.primId].normal(hitPoint);
				const Material* mat = scene.primitives[hit.primId].material;

				color = color + Vec3f(mat.emission) * mat.color * cost;

				if(mat.type == 0) {
					Vec3f rotatedDir = mapRectToCosineHemisphere(hitNormal, Vec2f([uniform_rng(), uniform_rng()]));

					Ray bounceRay = { hitPoint + rotatedDir * 0.01, rotatedDir};
					ray = bounceRay;

					cost = cost * mat.color * dot(ray.direction, hitNormal);
				}
			} else {
				// "sky" color
				color = color + Vec3f([0.0f, 0.005f, 0.015f]) * cost;
				break;
			}

			depth++;
		}

		return color;
	};
}