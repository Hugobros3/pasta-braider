import vector;
import rng;
import sphere_sampling_helper;
import performance;

struct BSDFSample {
    Vec3f direction;
    float pdf;
    Vec3f value;
}

struct BSDF {
    @nogc BSDFSample function(Vec3f, Vec3f)        sample;
    @nogc Vec3f      function(Vec3f, Vec3f, Vec3f) evaluate;
    @nogc float      function(Vec3f, Vec3f, Vec3f) pdf;
}

BSDF make_diffuse_bsdf(immutable Vec3f albedo)() {
    // TODO this is called a bsdf but all those functions assume we are in the upper hemisphere for pdfs
    // to be more correct we'd need to check for that and return a pdf of 0.0 when in the "lower" (refraction) hemi

    @nogc BSDFSample function(Vec3f, Vec3f) samplingFn = function(Vec3f incommingDir, Vec3f surfaceNormal) {
		immutable float hemiPdf = 1.0 / (2.0 * PI);
		Vec3f direction = mapRectToCosineHemisphere(surfaceNormal, Vec2f([uniform_rng(), uniform_rng()]));

        return BSDFSample(direction, hemiPdf, albedo * (1.0 / (2.0 * PI)));
    };

    @nogc Vec3f function(Vec3f, Vec3f, Vec3f) evalFn = function(Vec3f incommingdir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return albedo * (1.0 / (2.0 * PI));
    };

    @nogc float function(Vec3f, Vec3f, Vec3f) pdfFn = function(Vec3f incommingdir, Vec3f surfaceNormal, Vec3f outgoingDir) {
		immutable float hemiPdf = 1.0 / (2.0 * PI);
        return hemiPdf;
    };

    return BSDF(samplingFn, evalFn, pdfFn);
};