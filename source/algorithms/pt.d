import vector;
import performance;

Vec3f hemisphere(Vec2f uv) {
	const float r = sqrt(1.0f - uv.x * uv.x);
	const float phi = 2.0 * PI * uv.y;
	return Vec3f([cos(phi) * r, sin(phi) * r, uv.x]);
}