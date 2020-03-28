import vector;

struct Ray {
    Vec3f origin;
    Vec3f direction;
}

struct Hit {
    int primId = -1;
    float t;
}