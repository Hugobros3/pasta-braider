import vector;
import ray;
import material;

import uniform_sampling;
import fast_math;
import constants;

struct Triangle {
    const Vec3f v0, v1, v2;
    const Vec3f normal, e1, e2;
    const Material* material;
    immutable float invArea;

    this(Vec3f v0, Vec3f v1, Vec3f v2, const Material* material) {
        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
        this.e1 = v0 - v1;
        this.e2 = v2 - v0;
        this.normal = cross(e1, e2);
        this.material = material;
        this.invArea = 1.0 / area();
	}

    @nogc bool intersect(const ref Ray ray, ref float t) const {
        Vec3f p = cross(ray.direction, e2);
        float determinant = dot(e1, p);
        if(determinant > -EPSILON && determinant < EPSILON)
            return false;

        float inv_det = 1.0 / determinant;
        Vec3f tt = ray.origin - v0;
        
        float u = dot(tt, p) * inv_det;
        if(u < 0.0 || u > 1.0)
            return false;

        Vec3f q = cross(tt, e1);
        float v = dot(ray.direction, q) * inv_det;
        if(v < 0.0 || u + v > 1.0)
            return false;

        t = dot(e2, q) * inv_det;
        return true;
	}

    @nogc void random_point_on_surface(ref Vec3f position, ref Vec3f normal, ref float pdf) const {
        const float r1 = uniform_rng();
        const float r2 = uniform_rng();

        float alpha = 1 - sqrt(r1);
        float beta  = (1 - r2) * sqrt(r1);
        float gamma = r2 * sqrt(r1);

        position = alpha * v0 + beta * v1 + gamma * v2;
        normal = this.normal;
        pdf = invArea;
	}

    @nogc float area() const {
        return (cross(v0, v1) + cross(v1, v2) + cross(v2, v0)).length / 2.0f;
	}
}