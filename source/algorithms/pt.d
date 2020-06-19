import vector;
import performance;
import film;
import color;
import camera;
import ray;
import scene;
import material;
import light;
import sampling;
import rng;

import std.random;
import std.stdio;
import std.algorithm;
import std.math : isNaN;

immutable bool explicit_light_sampling = true;

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

			//if(depth > 1)
			//	break;
			
			Hit hit = scene.intersect(ray);

			if(hit.primId != -1) {
				Vec3f hitPoint = ray.origin + ray.direction * hit.t;
				Vec3f hitNormal = scene.primitives[hit.primId].normal(hitPoint);
				const Material* mat = scene.primitives[hit.primId].material;

				if(explicit_light_sampling) {
					Vec3f bsdf = (mat.color * (1.0 / PI));

					// Direct light sampling pick a random light
					Light light = scene.pickRandomLight();
					final switch(light.type) {
						case LightType.SKY:
							// Sampling the sky is done by picking a random direction, as the sky encloses the entire scene
							/*Vec3f dirToSky = sampleSphere(Vec2f([uniform_rng(), uniform_rng()]));
							Ray tryEscape = { hitPoint + dirToSky * 0.01, dirToSky};

							Hit lightConnection = scene.intersect(tryEscape);
							if(lightConnection.primId == -1) {
								color = color + light.sky.material.color * light.sky.material.emission * mat.color * dot(hitNormal, dirToSky) * cost * scene.lights.length;
							}*/
							break;
						case LightType.EMMISSIVE_PRIMITIVE: 
							// Pick a random point on the primitive
							Vec3f lightSamplePos;
							Vec3f lightSampleNorm;
							scene.primitives[light.primitive.index].randomPointOnSurface(lightSamplePos, lightSampleNorm);
							float area = scene.primitives[light.primitive.index].area(); 
						
							Vec3f dirToLight = (lightSamplePos - hitPoint).normalize();
							Ray rayToLight = { hitPoint + dirToLight * 0.01, dirToLight };
							float distanceToLight = (lightSamplePos - hitPoint).length();

							// TODO provide tMin/tMax in intersect to begin with
							Hit lightConnection = scene.intersect(rayToLight);
							if(lightConnection.primId == light.primitive.index && lightConnection.t <= distanceToLight + 0.01) {
								float solidAngle = max(0.0, dot(lightSampleNorm, dirToLight)) * (area / (distanceToLight * distanceToLight));
								const Material* lightMat = scene.primitives[light.primitive.index].material;
								Vec3f explicitRadianceContrib = lightMat.color * lightMat.emission * solidAngle * bsdf * max(0.0, dot(hitNormal, dirToLight)) * cost * scene.lights.length;

								color = color + explicitRadianceContrib;
							}

							break;
						case LightType.POINT: 
							/*Vec3f target = light.point.position;

							Vec3f dirToLight = (target - hitPoint).normalize();
							Ray rayToLight = { hitPoint + dirToLight * 0.01, dirToLight };
							float distanceToLight = (target - hitPoint).length();

							// TODO provide tMin/tMax in intersect to begin with
							Hit lightConnection = scene.intersect(rayToLight);
							if(lightConnection.primId == -1 || lightConnection.t > distanceToLight) {
								color = color + light.point.material.color * mat.color * max(0.0, dot(hitNormal, dirToLight)) * scene.lights.length;
							}*/
							break;
					}
				}

				if(!explicit_light_sampling) {
					// Non-NEE: add direct illumination here
					Vec3f L_e = Vec3f(mat.emission) * mat.color;
					color = color + L_e * cost * 2.0 * PI;
				}

				if(mat.type == 0) {
					Vec3f bounceDirection = mapRectToCosineHemisphere(hitNormal, Vec2f([uniform_rng(), uniform_rng()]));
					Vec3f bsdf = (mat.color * (1.0 / PI));

					Ray bounceRay = { hitPoint + bounceDirection * 0.01, bounceDirection};
					ray = bounceRay;

					if(mat.emission > 0.0) {
						if(explicit_light_sampling && depth == 0) {
							color = color + mat.color * mat.emission * cost;
						}

						break;
					}

					cost = cost * bsdf * dot(hitNormal, ray.direction);
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