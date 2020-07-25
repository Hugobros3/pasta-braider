import vector;

struct Ray {
    Vec3f origin;
    float tmin;
    Vec3f direction;
    float tmax;
}

struct Hit {
    int primId = -1;
    float t = float.infinity;
}