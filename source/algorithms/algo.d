import film;
import color;
import vector;
import camera;
import ray;
import scene;

auto make_debug_renderer(ColorSpace, PrimitiveType)() {
	return function RGB(immutable ref Camera camera, const Vec2i viewportSize, Vec2i pos, const ref Scene!(PrimitiveType) scene) @nogc { 
		Ray ray = generateRay(camera, viewportSize, pos);
		Hit hit = scene.intersect(ray);
		//return ray.direction;
		if(hit.primId != -1) {
			return RGB([1.0f, 0.0f, 0.0f]);
		}

		return RGB([0.0f, 0.5f, 1.0f]);
	};
}