import ray;

class Scene(PrimitiveType) 
    if(__traits(compiles, PrimitiveType.intersect))
{
    PrimitiveType[] primitives;

    final @nogc Hit intersect(Ray ray) const {
        float t;
        Hit hit;
        foreach(primId, primitive; primitives) {
            t = 0.0;
            if(primitive.intersect(ray, t)) {
                if(t < hit.t) {
                    hit.primId = cast(int)primId;
                    hit.t = t;
				}
			}
		}
        return hit;
	}
}

interface AccelerationStructure(PrimitiveType) {
    this(ref Scene!(PrimitiveType));

    Hit intersect(Ray ray);
}