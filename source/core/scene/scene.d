import ray;

import uniform_sampling;
import light;
import material;
import vector;

import bvh;
import null_as;

alias AS = Bvh;

class Scene(PrimitiveType) 
    if(__traits(compiles, PrimitiveType.intersect))
{
    Material[] materials;
    PrimitiveType[] primitives;
    Light[] lights;
    AS!PrimitiveType acceleration_structure;

    this() {
        acceleration_structure = AS!PrimitiveType(this);
	}

    SkyLight skyLight = { make_diffuse_material(Vec3f(0.0f), 0.0f) };

    final @nogc Hit intersect(Ray ray) const {
        return acceleration_structure.intersect(ray);
    }

    // Called when the scene is done being built
    void process() {
        addEmmissivePrimitives();
        findSkyLight();
        acceleration_structure.build();
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