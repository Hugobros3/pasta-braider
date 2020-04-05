import vector;

interface Film(ColorSpace) {
    pragma(inline, true)
    @nogc Vec2i size();

    @nogc void clear();

    pragma(inline, true)
    @nogc void add(Vec2i position, ColorSpace contribution);

    /*@nogc void draw(ColorSpace function(void*, Vec2i) renderFn)() {
		pragma(msg, T.stringof);
        foreach(x; 0 .. size.x) {
            foreach(y; 0 .. size.y) {
                add(Vec2i([x, y]), renderFn(this, Vec2i ([x, y]) ) );
            }
        }
    }*/
}