import ray;

class Scene(PrimitiveType) 
    if(__traits(compiles, PrimitiveType.intersect))
{
    PrimitiveType[] primitives;
}

interface AccelerationStructure(PrimitiveType) {
    this(ref Scene!(PrimitiveType));

    Hit intersect(Ray ray);
}