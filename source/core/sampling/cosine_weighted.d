import fast_math;
import vector;

// unused for now
@nogc Vec3f mapRectToCosineHemisphere(const Vec3f n, const Vec2f uv) {
    // create tnb:
    //http://jcgt.org/published/0006/01/01/paper.pdf
    float signZ = (n.z >= 0.0f) ? 1.0f : -1.0f;
    float a = -1.0f / (signZ + n.z);
    float b = n.x * n.y * a;
    Vec3f b1 = Vec3f([1.0f + signZ * n.x * n.x * a, signZ*b, -signZ * n.x]);
    Vec3f b2 = Vec3f([b, signZ + n.y * n.y * a, -n.y]);

    // remap uv to cosine distributed points on the hemisphere around n
    float phi = 2.0f * 3.141592 * uv.x;
    float cosTheta = sqrt(uv.y);
    float sinTheta = sqrt(1.0f - uv.y);
    return ((b1 * cos(phi) + b2 * sin(phi)) * cosTheta + n * sinTheta).normalize();
}