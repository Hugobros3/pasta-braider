import vector;
import fast_math;
import film;
import color;
import camera;
import ray;
import scene;
import material;
import light;
import constants;
import uniform_sampling;

// debug stuff
import std.random;
import std.stdio;
import std.algorithm;
import std.math : isNaN;

immutable bool explicit_light_sampling = true;

auto make_path_tracing_renderer(ColorSpace, PrimitiveType)() {

	return function RGB(immutable ref Camera camera, const Vec2i viewportSize, Vec2i pos, const ref Scene!(PrimitiveType) scene) @nogc { 
		Vec3f color = [ 0.0, 0.0, 0.0 ];

		bool last_specular = false;

		Ray ray = generateRay(camera, viewportSize, Vec2f([pos.x + uniform_rng(), pos.y + uniform_rng()]));

		int depth = 0;
		Vec3f weight = 1.0;
		while(true) {
			// TODO: proper russian roulette
			if(depth > 5)
				break;

			//if(depth > 1)
			//	break;
			
			Hit hit = scene.intersect(ray);

			if(hit.primId != -1) {
				Vec3f hitPoint = ray.origin + ray.direction * hit.t;
				Vec3f hitNormal = scene.primitives[hit.primId].normal(hitPoint);
				const Material* mat = scene.primitives[hit.primId].material;

				if(explicit_light_sampling && !mat.bsdf.is_specular) {
					//Vec3f bsdf = (mat.color * (1.0 / PI));

					Light light = scene.pickRandomLight();
					float pdf_light_source = 1.0 / scene.lights.length;

					final switch(light.type) {
						case LightType.SKY:
							// Sampling the sky is done by picking a random direction, as the sky encloses the entire scene
							/*Vec3f dirToSky = sampleSphere(Vec2f([uniform_rng(), uniform_rng()]));
							Ray tryEscape = { hitPoint + dirToSky * 0.01, dirToSky};

							Hit lightConnection = scene.intersect(tryEscape);
							if(lightConnection.primId == -1) {
								color = color + light.sky.material.color * light.sky.material.emission * mat.color * dot(hitNormal, dirToSky) * weight * scene.lights.length;
							}*/
							break;
						case LightType.EMMISSIVE_PRIMITIVE: 

							// Sample the light surface
							Vec3f lightSamplePos;
							Vec3f lightSampleNorm;
							scene.primitives[light.primitive.index].randomPointOnSurface(lightSamplePos, lightSampleNorm);
							float pdf_area = 1.0 / scene.primitives[light.primitive.index].area(); 
						
							// Point a ray towards it
							Vec3f dirToLight = (lightSamplePos - hitPoint).normalize();
							Ray rayToLight = { hitPoint + dirToLight * 0.01, dirToLight };
							float distanceToLight = (lightSamplePos - hitPoint).length();
							float d2 = distanceToLight * distanceToLight;
							float inv_d2 = 1.0 / d2;

							// TODO provide tMin/tMax in intersect to begin with
							Hit lightConnection = scene.intersect(rayToLight);
							if(lightConnection.primId == light.primitive.index && lightConnection.t <= distanceToLight + 0.01) {
								float pdf_point_on_light = pdf_light_source * pdf_area;

								float cos_e = max(0.0, dot(hitNormal,       dirToLight));
								float cos_l = max(0.0, dot(lightSampleNorm, dirToLight));

								const Material* lightMat = scene.primitives[light.primitive.index].material;

								//float pdf_e = mat.bsdf.pdf(ray.direction, hitNormal, rayToLight.direction);
								//float mis = 1.0f / (1.0 + pdf_e * cos_l * inv_d2 / pdf_point_on_light);
								float mis = 1.0;

								Vec3f explicitRadianceContrib = (lightMat.color * lightMat.emission) * mat.bsdf.evaluate(ray.direction, hitNormal, rayToLight.direction) * cos_e * cos_l * inv_d2 * (mis / pdf_point_on_light);

								//float solidAngle = max(0.0, dot(lightSampleNorm, dirToLight)) * (area / (distanceToLight * distanceToLight));
								//const Material* lightMat = scene.primitives[light.primitive.index].material;
								//Vec3f explicitRadianceContrib = lightMat.color * lightMat.emission * solidAngle * bsdf * max(0.0, dot(hitNormal, dirToLight)) * weight * scene.lights.length;

								color = color + explicitRadianceContrib * weight;
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

				if(!explicit_light_sampling || last_specular || depth == 0	) {
					Vec3f L_e = Vec3f(mat.emission) * mat.color;
					color = color + L_e * weight;
				}

				const auto bsdfSample = mat.bsdf.sample(-ray.direction, hitNormal);

				Ray bounceRay = { hitPoint + bsdfSample.direction * 0.01, bsdfSample.direction};
				ray = bounceRay;

				weight = weight * bsdfSample.value * (dot(hitNormal, ray.direction) / bsdfSample.pdf);
				last_specular = mat.bsdf.is_specular;
			} else {
				// "sky" color
				//color = color + Vec3f([0.0f, 0.005f, 0.015f]) * 10.0* weight;
				break;
			}

			depth++;
		}

		return color;
	};
}