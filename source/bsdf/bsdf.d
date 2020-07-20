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

abstract class BSDF {
    bool is_specular = false;
    abstract const @nogc BSDFSample sample(Vec3f, Vec3f);
    abstract const @nogc Vec3f evaluate(Vec3f, Vec3f, Vec3f);
    abstract const @nogc float pdf(Vec3f, Vec3f, Vec3f);
}

final class DiffuseBSDF : BSDF {
    Vec3f albedo;
    this(Vec3f albedo) {
        this.albedo = albedo;
	}

    final override const @nogc BSDFSample sample(Vec3f incommingDir, Vec3f surfaceNormal) {
		//auto bounce_dir_sample = sample_direction_hemisphere_uniform_with_normal(Vec2f([uniform_rng(), uniform_rng()]), surfaceNormal);
		auto bounce_dir_sample = sample_direction_hemisphere_cosine_weighted_with_normal2(Vec2f([uniform_rng(), uniform_rng()]), surfaceNormal);

		immutable float Kd = 1.0 / PI;
        return BSDFSample(bounce_dir_sample.direction, bounce_dir_sample.pdf, albedo * Kd);
    };

    final override const @nogc Vec3f evaluate(Vec3f incommingDir, Vec3f surfaceNormal, Vec3f outgoingDir) {
		immutable float Kd = 1.0 / PI;
        return albedo * Kd;
    };

    final override const @nogc float pdf(Vec3f incommingDir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return max(dot(incommingDir, surfaceNormal), 0.0) / PI;
		//return UNIFORM_SAMPLED_HEMISPHERE_PDF;
    };
}

BSDF make_diffuse_bsdf(immutable Vec3f albedo)() {
    // TODO this is called a bsdf but all those functions assume we are in the upper hemisphere for pdfs
    // to be more correct we'd need to check for that and return a pdf of 0.0 when in the "lower" (refraction) hemi
    return new DiffuseBSDF(albedo);
};

final class MirrorBSDF : BSDF {
    Vec3f albedo;
    this(Vec3f albedo) {
        this.albedo = albedo;
        is_specular = true;
	}

    final override const @nogc BSDFSample sample(Vec3f incommingDir, Vec3f surfaceNormal) {
        Vec3f direction = reflect(incommingDir, surfaceNormal);

        return BSDFSample(direction, 1.0f, albedo);
    };

    final override const @nogc Vec3f evaluate(Vec3f incommingDir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return albedo;
    };

    final override const @nogc float pdf(Vec3f incommingDir, Vec3f surfaceNormal, Vec3f outgoingDir) {
        return outgoingDir == reflect(incommingDir, surfaceNormal) ? 1.0f : 0.0f;
    };
}

BSDF make_mirror_bsdf(immutable Vec3f albedo)() {
    return new MirrorBSDF(albedo);
};