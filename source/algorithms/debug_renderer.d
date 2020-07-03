import film;
import color;
import vector;
import camera;
import ray;
import scene;
import material;

auto make_debug_renderer(ColorSpace, PrimitiveType)() {
    return function RGB(immutable ref Camera camera, const Vec2i viewportSize, Vec2i pos, const ref Scene!(PrimitiveType) scene) @nogc { 
        Ray ray = generateRay(camera, viewportSize, Vec2f([pos.x + 0.5f, pos.y + 0.5f]));
        Hit hit = scene.intersect(ray);

        if(hit.primId != -1) {
            const Material* mat = scene.primitives[hit.primId].material;
            return mat.color;
        }

        return RGB([0.0f, 0.5f, 1.0f]);
    };
}