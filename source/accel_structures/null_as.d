import ray;
import scene;

struct NullAS(PrimitiveType)
    if(__traits(compiles, PrimitiveType.intersect))
{
	Scene!PrimitiveType scene;

	this(Scene!PrimitiveType scene) {
		this.scene = scene;
	}

	@nogc Hit intersect(Ray ray) const {
		float t;
		Hit hit;
		foreach(primId, primitive; scene.primitives) {
			//t = ray.tmin;
			if(primitive.intersect(ray, t)) {
				if(ray.tmin <= t && t < ray.tmax) {
					hit.primId = cast(int)primId;
					hit.t = t;
					ray.tmax = t;
				}
			}
		}
		return hit;
	}

	void build() {

	}
}