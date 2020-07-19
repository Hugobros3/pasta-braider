import vector;
import uniform_sampling;
import cosine_weighted;
import fast_math;
import constants;
import std.algorithm : max;

struct BSDFSample {
    Vec3f direction;
    float pdf;
    Vec3f value;
}

struct BSDF {
    bool is_specular;
    @nogc BSDFSample function(Vec3f, Vec3f)        sample;
    @nogc Vec3f      function(Vec3f, Vec3f, Vec3f) evaluate;
    @nogc float      function(Vec3f, Vec3f, Vec3f) pdf;
}

BSDF make_diffuse_bsdf(immutable Vec3f albedo)() {
    // TODO this is called a bsdf but all those functions assume we are in the upper hemisphere for pdfs
    // to be more correct we'd need to check for that and return a pdf of 0.0 when in the "lower" (refraction) hemi

    @nogc BSDFSample function(Vec3f, Vec3f) samplingFn = function(Vec3f incommingDir, Vec3f surfaceNormal) {
		//auto bounce_dir_sample = sample_direction_hemisphere_uniform_with_normal(Vec2f([uniform_rng(), uniform_rng()]), surfaceNormal);
		auto bounce_dir_sample = sample_direction_hemisphere_cosine_weighted_with_normal2(Vec2f([uniform_rng(), uniform_rng()]), surfaceNormal);

		immutable float Kd = 1.0 / PI;
        return BSDFSample(bounce_dir_sample.direction, bounce_dir_sample.pdf, albedo * Kd);
    };

    @nogc Vec3f function(Vec3f, Vec3f, Vec3f) evalFn = function(Vec3f incommingDir, Vec3f surfaceNormal, Vec3f outgoingDir) {
		immutable float Kd = 1.0 / PI;
        return albedo * Kd;
    };

    @nogc float function(Vec3f, Vec3f, Vec3f) pdfFn = function(Vec3f incommingDir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return max(dot(incommingDir, surfaceNormal), 0.0) / PI;
		//return UNIFORM_SAMPLED_HEMISPHERE_PDF;
    };

    return BSDF(false, samplingFn, evalFn, pdfFn);
};

BSDF make_mirror_bsdf(immutable Vec3f albedo)() {
    // TODO this is called a bsdf but all those functions assume we are in the upper hemisphere for pdfs
    // to be more correct we'd need to check for that and return a pdf of 0.0 when in the "lower" (refraction) hemi

    @nogc BSDFSample function(Vec3f, Vec3f) samplingFn = function(Vec3f incommingDir, Vec3f surfaceNormal) {
        Vec3f direction = reflect(incommingDir, surfaceNormal);

        return BSDFSample(direction, 1.0f, albedo);
    };

    @nogc Vec3f function(Vec3f, Vec3f, Vec3f) evalFn = function(Vec3f incommingDir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return albedo;
    };

    @nogc float function(Vec3f, Vec3f, Vec3f) pdfFn = function(Vec3f incommingDir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return outgoingDir == reflect(incommingDir, surfaceNormal) ? 1.0f : 0.0f;
    };

    return BSDF(true, samplingFn, evalFn, pdfFn);
};