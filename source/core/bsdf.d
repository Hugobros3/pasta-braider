import vector;
import rng;
import sampling;
import performance;

struct BSDFSample {
    Vec3f direction;
    float pdf;
}

//alias BSDF = BSDFSample delegate();
struct BSDF {
    @nogc BSDFSample delegate(Vec3f, Vec3f) sample;
}

immutable BSDF diffuseBSDF = {
    delegate(Vec3f incommingDir, Vec3f surfaceNormal) {
        Vec3f direction = mapRectToCosineHemisphere(surfaceNormal, Vec2f([uniform_rng(), uniform_rng()]));
        float pdf = 1.0 / (2.0 * PI);

        return BSDFSample(direction, pdf);
    }
};