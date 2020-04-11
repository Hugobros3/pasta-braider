import vector;
import ray;

struct Camera {
    Vec3f position;
    Vec3f lookingAt;
    Vec3f up = [0, 1, 0];

    float planeDistance = 1f;

    Vec3f h, v;
    void update() {
		h = (cross(up, lookingAt));
		v = (cross(h, lookingAt));
	}
}

@nogc Ray generateRay(immutable ref Camera camera, const Vec2i viewportSize, const Vec2f viewportPosition) {
    float aspectRation = cast(float)viewportSize.x / cast(float)viewportSize.y;

    Vec2f ndc = Vec2f([viewportPosition.x, viewportPosition.y]) / Vec2f([viewportSize.x - 1, viewportSize.y - 1]);
    Vec3f lowerLeftCorner = (((camera.lookingAt) * camera.planeDistance) - camera.h) - camera.v;
    Vec3f rayDirection = (lowerLeftCorner + (camera.h * ndc.x * 2.0) + (camera.v * ndc.y * 2.0)).normalize();

    Ray ray = {
        origin: camera.position,
        direction: rayDirection
	};
    return ray;
}