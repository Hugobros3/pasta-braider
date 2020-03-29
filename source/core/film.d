import vector;

interface Film(ColorSpace) {
    Vec2i size();

    void clear();
    void add(Vec2i position, ColorSpace contribution);

    @nogc void draw(ColorSpace function(ref Film, Vec2i) renderFn)() {
        foreach(x; 0 .. size.x) {
            foreach(y; 0 .. sixe.z) {
                renderFn(this, [x, y]);
            }
        }
    }
}