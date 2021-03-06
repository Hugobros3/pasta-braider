import film;
import color;
import vector;
import camera;
import ray;
import scene;
import material;
import bsdf;
import light;

import fast_math;
import uniform_sampling;

import std.algorithm;

auto make_direct_lighting_renderer(ColorSpace, PrimitiveType)() {
    return function RGB(immutable ref Camera camera, const Vec2i viewportSize, Vec2i pos, const ref Scene!(PrimitiveType) scene) @nogc { 
        Ray ray = generateRay(camera, viewportSize, Vec2f([pos.x + uniform_rng(), pos.y + uniform_rng()]));
        Hit hit = scene.intersect(ray);

        if(hit.primId != -1) {
            //TODO shouldn't hitNormal be part of Hit ?
            Vec3f hitPoint = ray.origin + ray.direction * hit.t;
            Vec3f hitNormal = scene.primitives[hit.primId].normal(hitPoint);

            const MaterialRef mat = scene.primitives[hit.primId].material;
            const BSDFSample bsdfSample = mat.bsdf.sample(-ray.direction, hitNormal);

            Ray lightRay = { hitPoint + bsdfSample.direction * 0.01, 0.0, bsdfSample.direction, float.infinity };
            Hit lightHit = scene.intersect(lightRay);

            if(lightHit.primId != -1) {
                const MaterialRef lightMat = scene.primitives[lightHit.primId].material;
                const emittedLight = (lightMat.color * lightMat.emission);

                return bsdfSample.value * emittedLight * (1.0 / bsdfSample.pdf);
            } else {
                return RGB(0.0);
            }
        }

        return RGB(0.0);
    };
}

auto make_direct_lighting_renderer_explicit_light_sampling(ColorSpace, PrimitiveType)() {
    return function RGB(immutable ref Camera camera, const Vec2i viewportSize, Vec2i pos, const ref Scene!(PrimitiveType) scene) @nogc { 
        Ray ray = generateRay(camera, viewportSize, Vec2f([pos.x + uniform_rng(), pos.y + uniform_rng()]));
        Hit hit = scene.intersect(ray);

        if(hit.primId != -1) {
            //TODO shouldn't hitNormal be part of Hit ?
            Vec3f hitPoint = ray.origin + ray.direction * hit.t;
            Vec3f hitNormal = scene.primitives[hit.primId].normal(hitPoint);

            const MaterialRef mat = scene.primitives[hit.primId].material;

            const Light light = scene.pickRandomLight();
            float pdf_light_source = 1.0 / scene.lights.length;

            final switch(light.type) {
                case LightType.SKY:
                    // TODO
                    break;
                case LightType.EMMISSIVE_PRIMITIVE: 

                    // Sample the light surface
                    Vec3f lightSamplePos;
                    Vec3f lightSampleNorm;
                    float pdf_area;
					scene.primitives[light.primitive.index].random_point_on_surface(lightSamplePos, lightSampleNorm, pdf_area);
                    //float pdf_area = 1.0 / scene.primitives[light.primitive.index].area();

                    // Point a ray towards it
                    Vec3f dirToLight = (lightSamplePos - hitPoint).normalize();
                    Ray rayToLight = { hitPoint + dirToLight * 0.01, 0.0, dirToLight, float.infinity };
                    float distanceToLight = (lightSamplePos - hitPoint).length();
                    float d2 = distanceToLight * distanceToLight;
                    float inv_d2 = 1.0 / d2;

                    // TODO provide tMin/tMax in intersect to begin with
                    Hit lightConnection = scene.intersect(rayToLight);

                    // The ray connects, let's compute the contribution !
                    if(lightConnection.primId == light.primitive.index && lightConnection.t <= distanceToLight + 0.001) {
                        float pdf_point_on_light = pdf_light_source * pdf_area;

                        float cos_e = max(0.0, dot(hitNormal,       dirToLight));
                        float cos_l = max(0.0, dot(lightSampleNorm, -dirToLight));

                        const MaterialRef lightMat = scene.primitives[light.primitive.index].material;

                        //float pdf_e = mat.bsdf.pdf(ray.direction, hitNormal, rayToLight.direction);
                        //float mis = 1.0f / (1.0 + pdf_e * cos_l * inv_d2 / pdf_point_on_light);
                        float mis = 1.0;
                        
                        return (lightMat.color * lightMat.emission) * mat.bsdf.evaluate(ray.direction, hitNormal, rayToLight.direction) * cos_e * cos_l * inv_d2 * (mis / pdf_point_on_light);
                    }

                    break;
                case LightType.POINT: 
                    // TODO
                    break;
            }

            return RGB(0.0);
        }

        return RGB(0.0);
    };
}