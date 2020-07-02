import vector;
import uniform_sampling;
import fast_math;
import constants;

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
		//Vec3f direction = mapRectToCosineHemisphere(surfaceNormal, Vec2f([uniform_rng(), uniform_rng()]));

        Vec3f direction = sample_random_direction_uniform(Vec2f([uniform_rng(), uniform_rng()]));

        // Fold uniform sampled sphere on itself !
        if(dot(direction, surfaceNormal) < 0) {
            direction = -direction;
		}

		immutable float Kd = 1.0 / (2.0 * PI);
        return BSDFSample(direction, UNIFORM_SAMPLED_HEMISPHERE_PDF, albedo * Kd);
    };

    @nogc Vec3f function(Vec3f, Vec3f, Vec3f) evalFn = function(Vec3f incommingdir, Vec3f surfaceNormal, Vec3f outgoingDir) {
		immutable float Kd = 1.0 / (2.0 * PI);
        return albedo * Kd;
    };

    @nogc float function(Vec3f, Vec3f, Vec3f) pdfFn = function(Vec3f incommingdir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return UNIFORM_SAMPLED_HEMISPHERE_PDF;
    };

    return BSDF(samplingFn, evalFn, pdfFn);
};