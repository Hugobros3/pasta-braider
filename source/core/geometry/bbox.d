import vector;

struct BBox(int dim, T) {
    Vec!(dim, T) min, max;
}

alias BBox3f = BBox!(3, float);