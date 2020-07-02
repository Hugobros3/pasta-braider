import vector;

interface Film(ColorSpace) {
    pragma(inline, true)
    @nogc Vec2i size();

    @nogc void clear();

    pragma(inline, true)
    @nogc void add(Vec2i position, ColorSpace contribution);
}