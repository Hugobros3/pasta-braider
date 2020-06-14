import vector;
import performance;
import film;
import color;
import camera;
import ray;
import scene;
import material;
import light;

import rng;

import std.random;
import std.stdio;

@nogc Vec3f sampleSphere(Vec2f uv) {
	const float sign = uv.x > 0.5 ? 1.0 : -1.0;
	const float uvx = (uv.x * 2.0) % 1.0;

	const float r = sqrt(1.0f - uvx * uvx) * sign;
	const float phi = 2.0 * PI * uv.y;
	return Vec3f([cos(phi) * r, sin(phi) * r, uv.x]);
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

				// Direct light sampling pick a random light
				Light light = scene.pickRandomLight();
				final switch(light.type) {
					case LightType.SKY:

						// Sampling the sky is done by picking a random direction, as the sky encloses the entire scene
						Vec3f dirToSky = sampleSphere(Vec2f([uniform_rng(), uniform_rng()]));
						Ray tryEscape = { hitPoint + dirToSky * 0.01, dirToSky};
						Hit lightConnection = scene.intersect(tryEscape);
						if(lightConnection.primId == -1) {
							color = color + light.sky.material.color * light.sky.material.emission * mat.color * dot(hitNormal, dirToSky) * cost;
						}
						break;
					case LightType.EMMISSIVE_PRIMITIVE: 
						// Pick a random point on the primitive
						
						break;
					case LightType.POINT: 
						
						Vec3f target = light.point.position;
						Vec3f dirToLight = (target - hitPoint).normalize();
						Ray rayToLight = { hitPoint + dirToLight * 0.01, dirToLight };
						float distanceToLight = (target - hitPoint).length();

						// TODO provide tMin/tMax in intersect to begin with
						Hit lightConnection = scene.intersect(rayToLight);
						if(lightConnection.primId == -1 || lightConnection.t > distanceToLight) {
							color = color + light.point.material.color * mat.color * dot(hitNormal, dirToLight) * cost;
						}
						break;
				}

				// Non-NEE: add direct illumination here
				// color = color + Vec3f(mat.emission) * mat.color * cost;

				if(mat.type == 0) {
					Vec3f rotatedDir = mapRectToCosineHemisphere(hitNormal, Vec2f([uniform_rng(), uniform_rng()]));

					Ray bounceRay = { hitPoint + rotatedDir * 0.01, rotatedDir};
					ray = bounceRay;

					cost = cost * mat.color * dot(ray.direction, hitNormal);
				}
			} else {
				// "sky" color
				//color = color + Vec3f([0.0f, 0.005f, 0.015f]) * 10.0* cost;
				break;
			}

			depth++;
		}

		return color;
	};
}