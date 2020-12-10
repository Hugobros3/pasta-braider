import film;
import color;
import vector;
import camera;
import ray;
import scene;
import material;

import std.typecons;

alias HeatmapColorPoint = Tuple!(Vec3i, "color", int, "intensity");

static HeatmapColorPoint[8] colors = [
	HeatmapColorPoint(Vec3i([ 87,   0, 127 ]),   0),
    HeatmapColorPoint(Vec3i([ 68,   0, 206 ]),   8),
    HeatmapColorPoint(Vec3i([  0,  76, 255 ]),  16),
    HeatmapColorPoint(Vec3i([  0, 165, 255 ]),  32),
    HeatmapColorPoint(Vec3i([  0, 255, 182 ]),  64),
    HeatmapColorPoint(Vec3i([182, 255,   0 ]), 128),
    HeatmapColorPoint(Vec3i([255,   0,   0 ]), 256),
    HeatmapColorPoint(Vec3i([255, 255, 255 ]), 512),
	];

@nogc
Vec3f to_rgb(HeatmapColorPoint p) {
    float s = 1.0f / 255.0f;
    Vec3f color = Vec3f([p.color.data[0] * s, p.color.data[1] * s, p.color.data[2] * s]);
    return color;
}

@nogc
Vec3f color_for(int steps) {
    int matchBi = 0;
    HeatmapColorPoint matchB = colors[cast(int)colors.length - 1];
    for(int i = 0; i < colors.length; i++) {
        if(colors[i].intensity > steps) {
            matchB = colors[i];
            matchBi = i;
            break;
        }
    }

    if(matchB.intensity == steps || matchB.intensity == 0 || steps > matchB.intensity)
        return to_rgb(matchB);

    HeatmapColorPoint matchA = colors[matchBi - 1];
    float delta = matchB.intensity - matchA.intensity;
    float dist = steps - matchA.intensity;
    float lerp = dist / delta;
    float olerp = 1.0f - lerp;
    Vec3f colorA = to_rgb(matchA);
    Vec3f colorB = to_rgb(matchB);
    return colorB * lerp + colorA * olerp;
}


auto make_complexity_renderer(ColorSpace, PrimitiveType)() {
    return function RGB(immutable ref Camera camera, const Vec2i viewportSize, Vec2i pos, const ref Scene!(PrimitiveType) scene) @nogc {
        immutable TraversalParameters traversal_parameters = {
            any_hit: false, return_stats: true
		};

        Ray ray = generateRay(camera, viewportSize, Vec2f([pos.x + 0.5f, pos.y + 0.5f]));
        auto raysult = scene.intersect!(traversal_parameters)(ray);
        Hit hit = raysult[0];
        TraversalStats stats = raysult[1];

		return color_for(stats.visited_nodes);
    };
}