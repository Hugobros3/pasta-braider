import ray;

import uniform_sampling;
import light;

class Scene(PrimitiveType) 
    if(__traits(compiles, PrimitiveType.intersect))
{
    PrimitiveType[] primitives;
    Light[] lights;

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

    void addEmmissivePrimitives() {
        foreach(primId, primitive; primitives) {
            if(primitive.material.emission > 0.0) {
                Light light = {
                    type: LightType.EMMISSIVE_PRIMITIVE,
                    primitive: EmmissivePrimitive(cast(int)primId)
				};
                lights ~= light;
			}
		}
	}

    final @nogc Light pickRandomLight() const {
        return lights[uniform_range(0, cast(int)lights.length)];
	}
}

interface AccelerationStructure(PrimitiveType) {
    this(ref Scene!(PrimitiveType));

    Hit intersect(Ray ray);
}