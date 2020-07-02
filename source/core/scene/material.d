import vector;
import bsdf;

struct Material {
	Vec3f color;
	float emission = 0.0f;
	BSDF bsdf;
}

Material make_diffuse_material(immutable Vec3f albedo, float emission)() {
	immutable Vec3f albedo2 = albedo;
	return Material(albedo, emission, make_diffuse_bsdf!(albedo));
}