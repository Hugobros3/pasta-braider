import ray;

class Scene(PrimitiveType) {
    PrimitiveType[] primitives;
}

interface AccelerationStructure(PrimitiveType) {
    this(ref Scene!(PrimitiveType));

    Hit intersect(Ray ray);
}