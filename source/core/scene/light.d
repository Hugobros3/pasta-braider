import vector;
import material;

enum LightType {
	SKY,
	EMMISSIVE_PRIMITIVE,
	POINT
}

struct SkyLight {
	Material material;
}

struct PointLight {
	Material material;
	Vec3f position;
}

struct EmmissivePrimitive {
	int index;
}

struct Light {
	LightType type;
	//union {
		SkyLight sky;
		PointLight point;
		EmmissivePrimitive primitive;
	//}
}