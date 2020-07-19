import std.random;

import fast_math;
import vector;
import constants;

Mt19937 rng;

void seedRng() {
    rng.seed(unpredictableSeed);
}

/// Generates a uniform random value between 0 and 1.0
@nogc float uniform_rng() {
    float val = (float(rng.front) * (1.0f / ((uint.max))));
    rng.popFront();
    return val;
}

@nogc int uniform_range(int lower, int upper) {
    int val = rng.front % (upper - lower); // bad ! modulo is slowz ...
    rng.popFront();
    return val + lower;
}

struct SampledDirection {
    Vec3f direction;
    float pdf;
}

immutable float UNIFORM_SAMPLED_SPHERE_PDF = 1.0 / (4.0 * PI);
@nogc SampledDirection sample_direction_sphere_uniform(Vec2f randomVals) {
    // from https://www.bogotobogo.com/Algorithms/uniform_distribution_sphere.php
    float theta = 2.0*PI*randomVals.x;
    float phi = acos(2.0*randomVals.y-1.0);

    Vec3f direction = Vec3f([cos(theta)*sin(phi), sin(theta)*sin(phi), cos(phi)]);
    return SampledDirection(direction, UNIFORM_SAMPLED_SPHERE_PDF);
}

immutable float UNIFORM_SAMPLED_HEMISPHERE_PDF = 1.0 / (2.0 * PI);
@nogc SampledDirection sample_direction_hemisphere_uniform(Vec2f randomVals) {
    float phi = 2.0*PI*randomVals.x;
    float theta = acos(randomVals.y);

    float s = sqrt(1 - randomVals.y * randomVals.y);

    Vec3f direction =  Vec3f([cos(phi) * s, sin(phi) * s, randomVals.y]);
    return SampledDirection(direction, UNIFORM_SAMPLED_HEMISPHERE_PDF);
}

@nogc SampledDirection sample_direction_hemisphere_uniform_with_normal(Vec2f randomVals, Vec3f normal) {
    Vec3f direction = sample_direction_sphere_uniform(Vec2f([uniform_rng(), uniform_rng()])).direction;
	if(dot(direction, normal) < 0) {
		// Fold uniform sampled sphere on itself !
		direction = -direction;
	}
    return SampledDirection(direction, UNIFORM_SAMPLED_HEMISPHERE_PDF);
}