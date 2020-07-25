import vector;
import bsdf;

class Material {
    Vec3f color;
    float emission = 0.0f;
    BSDF bsdf;

    this(Vec3f c, float e, BSDF b) {
        this.color = c;
        this.emission = e;
        this.bsdf = b;
	}
}

alias MaterialRef = Material;

const(MaterialRef) reference(const ref Material material) {
    return cast(Material)material;
}

Material make_diffuse_material(Vec3f albedo, float emission) {
    return new Material(albedo, emission, make_diffuse_bsdf(albedo));
}

Material make_mirror_material(Vec3f albedo) {
    return new Material(albedo, 0.0f, make_mirror_bsdf(albedo));
}