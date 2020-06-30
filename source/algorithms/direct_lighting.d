import film;
import color;
import vector;
import camera;
import ray;
import scene;
import material;
import bsdf;

auto make_direct_lighting_renderer(ColorSpace, PrimitiveType)() {
	return function RGB(immutable ref Camera camera, const Vec2i viewportSize, Vec2i pos, const ref Scene!(PrimitiveType) scene) @nogc { 
		Ray ray = generateRay(camera, viewportSize, Vec2f([pos.x + 0.5f, pos.y + 0.5f]));
		Hit hit = scene.intersect(ray);

		if(hit.primId != -1) {
			//TODO shouldn't hitNormal be part of Hit ?
			Vec3f hitPoint = ray.origin + ray.direction * hit.t;
			Vec3f hitNormal = scene.primitives[hit.primId].normal(hitPoint);

			const Material* mat = scene.primitives[hit.primId].material;
			const BSDFSample bsdfSample = mat.bsdf.sample(ray.direction, hitNormal);

			const cosTerm = dot(hitNormal, bsdfSample.direction);
			Ray lightRay = { hitPoint + bsdfSample.direction * 0.01, bsdfSample.direction };
			Hit lightHit = scene.intersect(lightRay);

			if(lightHit.primId != -1) {
				const Material* lightMat = scene.primitives[lightHit.primId].material;

				return mat.color * lightMat.color * (lightMat.emission * cosTerm / bsdfSample.pdf);
			} else {
				return RGB(0.0);
			}
		}

		return RGB(0.0);
	};
}