import vector;
import ray;
import material;
import bbox;

import uniform_sampling;
import fast_math;
import constants;

import std.math : abs;

struct Triangle {
    Vec3f v0, v1, v2;
    Vec3f _normal, e1, e2;
    MaterialRef material;
    float invArea;

    /*this(Vec3f v0, Vec3f v1, Vec3f v2, const ref Material material) {
        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
        this.e1 = v1 - v0;
        this.e2 = v2 - v0;
        this._normal = cross(-e1, e2);
        this.material = material;
        this.invArea = 1.0 / area();
	}*/
	
	this(Vec3f v0, Vec3f v1, Vec3f v2, Vec3f n, ref Material material) {
        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
        this.e1 = v1 - v0;
        this.e2 = v2 - v0;
        this._normal = n;
        this.material = material.reference();
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

        float ft = dot(e2, q) * inv_det;
        if(ft > 0.0) {
            t = ft;
            return true;
		}
        return false;
	}

    @nogc Vec3f normal(const ref Vec3f p) const {
        return _normal;
    }

    @nogc void random_point_on_surface(ref Vec3f position, ref Vec3f normal, ref float pdf) const {
        const float r1 = uniform_rng();
        const float r2 = uniform_rng();

        float sqrtR1 = sqrt(r1);

        float alpha = 1 - sqrtR1;
        float beta  = (1 - r2) * sqrtR1;
        float gamma = r2 * sqrtR1;

        position = alpha * v0 + beta * v1 + gamma * v2 + _normal * 0.001;
        normal = this._normal;
        pdf = invArea;
	}

    @nogc float area() const {
        return (cross(v0, v1) + cross(v1, v2) + cross(v2, v0)).length / 2.0f;
	}

    @nogc BBox3f bbox() const {
        BBox3f bbox = v0;
        bbox = bbox.expand(v0);
        bbox = bbox.expand(v1);
		bbox = bbox.expand(v2);
        return bbox;
    }

    @nogc Vec3f center() const {
        return (v0 + v1 + v2) * (1.0 / 3.0);
	}
}