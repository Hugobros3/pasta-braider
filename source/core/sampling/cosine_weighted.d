import fast_math;
import std.math : abs;
import vector;
import uniform_sampling;
import constants;

/// Generates a cosine-weighted sample on a hemisphere
@nogc SampledDirection sample_direction_hemisphere_cosine_weighted(const Vec2f randomVals) {
    float phi = 2.0*PI*randomVals.x;
    float theta = acos(sqrt(randomVals.y));

    float s = sqrt(1 - randomVals.y);

    //float pdf = cos(theta) * INVPI;
    float pdf = sqrt(randomVals.y) * INVPI;

    Vec3f direction =  Vec3f([cos(phi) * s, sin(phi) * s, sqrt(randomVals.y)]);
    return SampledDirection(direction, pdf);
}

/// Creates tangent vectors from normal vector
/// from pbrt
@nogc void generate_tangents(Vec3f v1, ref Vec3f v2, ref Vec3f v3) {
	if(abs(v1.x) > abs(v1.y)) {
		float invLen = 1.0 / v1.xz.length();
		v2 = Vec3f([-v1.z * invLen, 0.0, v1.x * invLen]);
	} else {
		float invLen = 1.0 / v1.yz.length();
		v2 = Vec3f([0.0, v1.z * invLen, -v1.y * invLen]);
	}
	v3 = cross(v1, v2);
}

/// Generates a cosine-weighted sample on a hemisphere wrt to the given normal
@nogc SampledDirection sample_direction_hemisphere_cosine_weighted_with_normal(Vec2f randomVals, Vec3f normal) {
    auto sample = sample_direction_hemisphere_cosine_weighted(randomVals);

    Vec3f t1, t2;
    generate_tangents(normal, t1, t2);

    Vec3f mapped_dir = t1 * sample.direction.x + t2 * sample.direction.y + normal * sample.direction.z;

    return SampledDirection(mapped_dir, sample.pdf);
}

/// Alternative all-in-one function with fancy crap I don't understand fully
/// Works as regular sample_direction_hemisphere_cosine_weighted_with_normal
@nogc SampledDirection sample_direction_hemisphere_cosine_weighted_with_normal2(const Vec2f uv, const Vec3f n) {
    // create tnb:
    //http://jcgt.org/published/0006/01/01/paper.pdf
    float signZ = (n.z >= 0.0f) ? 1.0f : -1.0f;
    float a = -1.0f / (signZ + n.z);
    float b = n.x * n.y * a;
    Vec3f b1 = Vec3f([1.0f + signZ * n.x * n.x * a, signZ*b, -signZ * n.x]);
    Vec3f b2 = Vec3f([b, signZ + n.y * n.y * a, -n.y]);

    // remap uv to cosine distributed points on the hemisphere around n
    float phi = 2.0f * PI * uv.x;
    float cosTheta = sqrt(1.0 - uv.y);
    float sinTheta = sqrt(uv.y);

    Vec3f direction = ((b1 * cos(phi) + b2 * sin(phi)) * sinTheta + n * cosTheta).normalize();
    float pdf = cosTheta * INVPI;
    return SampledDirection(direction, pdf);
}