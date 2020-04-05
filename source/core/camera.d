import vector;
import ray;

struct Camera {
    Vec3f position;
    Vec3f lookingAt;
    Vec3f up = [0, 1, 0];

    float planeDistance = 1f;
}

@nogc Ray generateRay(const ref Camera camera, const Vec2i viewportSize, const Vec2i viewportPosition) {
    float aspectRation = cast(float)viewportSize.x / cast(float)viewportSize.y;
    Vec3f up = camera.up;
    Vec3f h = (cross(up, camera.lookingAt));//.normalize();
    Vec3f v = (cross(h, camera.lookingAt));//.normalize();

    Vec2f ndc = Vec2f([viewportPosition.x, viewportPosition.y]) / Vec2f([viewportSize.x - 1, viewportSize.y - 1]);
    Vec3f lowerLeftCorner = (((camera.lookingAt) * camera.planeDistance) - h) - v;
    Vec3f rayDirection = (lowerLeftCorner + (h * ndc.x * 2.0) + (v * ndc.y * 2.0)).normalize();

    Ray ray = {
        origin: camera.position,
        direction: rayDirection
	};
    return ray;
}