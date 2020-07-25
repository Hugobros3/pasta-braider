import ray;

struct NullAS(PrimitiveType)
    if(__traits(compiles, PrimitiveType.intersect))
{
	PrimitiveType[] primitives;

	this(PrimitiveType[] primitives) {
		this.primitives = primitives;
	}

	final @nogc Hit intersect(Ray ray) const {
		float t;
		Hit hit;
		foreach(primId, primitive; primitives) {
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
}