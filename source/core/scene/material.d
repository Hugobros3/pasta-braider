import vector;
import bsdf;

struct Material {
    Vec3f color;
    float emission = 0.0f;
    BSDF bsdf;
}

MaterialRef reference(const ref Material material) {
    return cast(MaterialRef)&material;
}

alias MaterialRef = Material*;

Material make_diffuse_material(immutable Vec3f albedo, float emission)() {
    return Material(albedo, emission, make_diffuse_bsdf!(albedo));
}

Material make_mirror_material(immutable Vec3f albedo)() {
    return Material(albedo, 0.0f, make_mirror_bsdf!(albedo));
}