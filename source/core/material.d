import vector;
import bsdf;

struct Material {
	Vec3f color;
	float emission = 0.0f;
	BSDF bsdf = diffuseBSDF;
}