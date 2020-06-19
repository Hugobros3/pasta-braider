import vector;
import ray;
import material;
import sampling;

import performance;
import rng;

struct Sphere {
    Vec3f center;
    float radius;
    Material* material;

    @nogc bool intersect(const ref Ray ray, ref float t) const {
        const auto oc = (ray.origin - center);//.normalize();
        const float a = 1.0;//dot(ray.direction, ray.direction);
        const float b = 2.0f * dot(oc, ray.direction);
        const float c = dot(oc, oc) - radius * radius;

        const float discriminantSquared = b * b - 4 * a * c;

        if (discriminantSquared < 0)
            return false;
        
        if (discriminantSquared == 0.0) {
            t = (-b) / (2 * a);
            return true;
        }

        const float discriminant = sqrt(discriminantSquared);
    
        const float sol1 = - b - discriminant;
        const float sol2 = - b + discriminant;

        if(sol1 > 0.0) {
            t = sol1 / (2 * a);
            return true;
        } else if(sol2 > 0.0) {
            t = sol2 / (2 * a);
            return true;
        } else {
            return false;
        }
    }

    @nogc Vec3f normal(const ref Vec3f p) const {
        return (p - center) * (1.0 / radius);
	}

    @nogc const void randomPointOnSurface(ref Vec3f position, ref Vec3f normal) {
        normal = sampleSphere(Vec2f([uniform_rng(), uniform_rng()]));
        position = normal * radius + center;
	}

    @nogc const float area() {
        return 4.0 * PI * radius * radius;
	}
}