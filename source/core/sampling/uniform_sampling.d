import std.random;

import fast_math;
import vector;
import constants;

Mt19937 rng;

void seedRng() {
    rng.seed(unpredictableSeed);
}

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

immutable float UNIFORM_SAMPLED_SPHERE_PDF = 1.0 / (4.0 * PI);
immutable float UNIFORM_SAMPLED_HEMISPHERE_PDF = 1.0 / (2.0 * PI);

/// pdf = 1.0 / 4PI
@nogc Vec3f sample_random_direction_uniform(Vec2f uv) {
    /*//const float sign = uv.x > 0.5 ? 1.0 : -1.0;
    const float uvx = (uv.x * 2.0) - 1.0;

    const float r = sqrt(1.0f - uvx * uvx);// * sign;
    const float phi = 2.0 * PI * uv.y;
    //return sampleHemisphere(uv);
    return Vec3f([cos(phi) * r, sin(phi) * r, uvx]);
    */

    // https://www.bogotobogo.com/Algorithms/uniform_distribution_sphere.php
    float theta = 2.0*PI*uv.x;
    float phi = acos(2.0*uv.y-1.0);
    // incorrect
    //phi = PI*irand(0,1);
    return Vec3f([cos(theta)*sin(phi), sin(theta)*sin(phi), cos(phi)]);
}