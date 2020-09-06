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

struct TraversalParameters {
    bool any_hit;
    bool return_stats;
}

immutable TraversalParameters DEFAULT_TRAVERSAL_PARAMETERS = {
    any_hit: false,
    return_stats: false,
};

struct TraversalStats {
    int tested_triangles = 0;
    int visited_nodes = 0;
}