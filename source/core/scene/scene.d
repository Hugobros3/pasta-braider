import ray;

import uniform_sampling;
import light;
import material;
import vector;

class Scene(PrimitiveType) 
    if(__traits(compiles, PrimitiveType.intersect))
{
    Material[] materials;
    PrimitiveType[] primitives;
    Light[] lights;

    SkyLight skyLight = { make_diffuse_material(Vec3f(0.0f), 0.0f) };

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

    void preProcessLights() {
        addEmmissivePrimitives();
        findSkyLight();
    }

    private void addEmmissivePrimitives() {
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

    private void findSkyLight() {
        foreach(light; lights) {
            if(light.type == LightType.SKY) {
                skyLight = light.sky;
            }
        }
    }

    final @nogc const(Light) pickRandomLight() const {
        return lights[uniform_range(0, cast(int)lights.length)];
    }
}

interface AccelerationStructure(PrimitiveType) {
    this(ref Scene!(PrimitiveType));

    Hit intersect(Ray ray);
}