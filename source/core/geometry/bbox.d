import vector;
import ray;

import std.typecons;

struct BBox(int dim, T) {
    Vec!(dim, T) pmin = 0;
	Vec!(dim, T) pmax = 0;

	@disable this();

	this(Vec!(dim, T) point) {
		pmin = point;
		pmax = point;
	}
	
	this(Vec!(dim, T) min, Vec!(dim, T) max) {
		pmin = min;
		pmax = max;
	}

	Vec!(dim, T) extends() const {
		return pmax - pmin;
	}

	float half_area() const {
		auto ext = extends();
		return (ext.x * (ext.y + ext.z) + ext.y * ext.z);
	}

	float area() const {
		return 2.0 * half_area;
	}

	BBox!(dim, T) expand(const Vec!(dim, T) point) const {
		BBox!(dim, T) n = BBox!(dim, T) (min(this.pmin, point), max(this.pmax, point) );
		return n;
	}

	BBox!(dim, T) expand(BBox!(dim, T) other) const {
		return this.expand(other.pmin).expand(other.pmax);
	}
}

alias BBox3f = BBox!(3, float);

pragma(inline, true)
@nogc float fast_multiply_add(float a, float b, float c) {
    return a * b + c;
}

pragma(inline, true)
@nogc Tuple!(float, float) intersect(const ref BBox3f bbox, const ref Ray ray, const Vec3f ray_inv_dir) {
	import std.algorithm.comparison;
    float txmin = fast_multiply_add(bbox.pmin.x, ray_inv_dir.x, -(ray.origin.x * ray_inv_dir.x));
    float txmax = fast_multiply_add(bbox.pmax.x, ray_inv_dir.x, -(ray.origin.x * ray_inv_dir.x));
    float tymin = fast_multiply_add(bbox.pmin.y, ray_inv_dir.y, -(ray.origin.y * ray_inv_dir.y));
    float tymax = fast_multiply_add(bbox.pmax.y, ray_inv_dir.y, -(ray.origin.y * ray_inv_dir.y));
    float tzmin = fast_multiply_add(bbox.pmin.z, ray_inv_dir.z, -(ray.origin.z * ray_inv_dir.z));
    float tzmax = fast_multiply_add(bbox.pmax.z, ray_inv_dir.z, -(ray.origin.z * ray_inv_dir.z));

    auto t0x = min(txmin, txmax);
    auto t1x = max(txmin, txmax);
    auto t0y = min(tymin, tymax);
    auto t1y = max(tymin, tymax);
    auto t0z = min(tzmin, tzmax);
    auto t1z = max(tzmin, tzmax);

    auto t0 = max(max(t0x, t0y), max(ray.tmin, t0z));
    auto t1 = min(min(t1x, t1y), min(ray.tmax, t1z));

    return tuple(t0, t1);
}
