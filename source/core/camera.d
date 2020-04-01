import vector;
import ray;

struct Camera {
    Vec3f position;
    Vec3f lookingAt;
    Vec3f up = [0, 1, 0];

    float planeDistance = 0.1f;
}

@nogc Ray generateRay(const ref Camera camera, const Vec2i viewportSize, const Vec2i viewportPosition) {
    float aspectRation = cast(float)viewportSize.x / cast(float)viewportSize.y;
    Vec3f up = camera.up;
    Vec3f h = (cross(up, camera.lookingAt)).normalize();
    Vec3f v = (cross(up, h)).normalize();

    Vec2f ndc = Vec2f([viewportPosition.x, viewportPosition.y]) / Vec2f([viewportSize.x - 1, viewportSize.y - 1]);
    Vec3f lowerLeftCorner = (camera.lookingAt).normalize() * camera.planeDistance - h * 0.5 - v * 0.5;
    Vec3f rayDirection = (lowerLeftCorner + h * ndc.x + v * ndc.y).normalize();

    Ray ray = {
        origin: camera.position,
        direction: rayDirection
	};
    return ray;
}