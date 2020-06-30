import vector;
import rng;
import sampling;
import performance;

struct BSDFSample {
    Vec3f direction;
    float pdf;
    Vec3f value;
}

struct BSDF {
    @nogc BSDFSample function(Vec3f, Vec3f)        sample;
    @nogc Vec3f      function(Vec3f, Vec3f, Vec3f) evaluate;
}

BSDF make_diffuse_bsdf(immutable Vec3f albedo)() {
    @nogc BSDFSample function(Vec3f, Vec3f) samplingFn = function(Vec3f incommingDir, Vec3f surfaceNormal) {
        Vec3f direction = mapRectToCosineHemisphere(surfaceNormal, Vec2f([uniform_rng(), uniform_rng()]));
        float pdf = 1.0 / (2.0 * PI);

        return BSDFSample(direction, pdf, albedo * (1.0 / (2.0 * PI)));
    };

    @nogc Vec3f function(Vec3f, Vec3f, Vec3f) evalFn = function(Vec3f incommingdir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return albedo * (1.0 / (2.0 * PI));
    };

    return BSDF(samplingFn, evalFn);
};