import vector;

interface Film(ColorSpace) {
    Vec2i size();

    void clear();
    void add(Vec2i position, ColorSpace contribution);
}