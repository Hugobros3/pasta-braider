import scene;
import sphere;

import material;
import vector;
import light;

private { 
}

Scene!Sphere make_balls_scene() {
    Material emmissiveMat =      make_diffuse_material( Vec3f([1.0, 0.5, 0.0]), 10.0f );
    Material veryEmmissiveMat =  make_diffuse_material( Vec3f([1.0, 0.0, 1.0]), 2.0f );
    Material veryEmmissiveMat2 = make_diffuse_material( Vec3f([0.0, 1.0, 0.0]), 2.0f );

    Material diffuseRedMat =     make_diffuse_material( Vec3f([1.0, 0.0, 0.0]), 0.0f );
    Material diffuseGreyMat =    make_diffuse_material( Vec3f([0.8, 0.8, 0.8]), 0.0f );
    Material skyMaterial =       make_diffuse_material( Vec3f([0.0f, 0.05f, 0.15f]), 0.5f);

    Material mirrorMat =         make_mirror_material( Vec3f([1.0, 1.0, 1.0]));

    auto scene = new Scene!Sphere();

    scene.primitives ~= Sphere(Vec3f([10.0, -100.0, 0.0]), 98.5f, diffuseGreyMat);

    scene.primitives ~= Sphere(Vec3f([12.0, 10.0, -5.0]), 1.5f, emmissiveMat);

    scene.primitives ~= Sphere(Vec3f([8.5, 0.0, 0.0]), 0.5f, veryEmmissiveMat);
    scene.primitives ~= Sphere(Vec3f([6.5, -1.0, 3.0]), 0.5f, veryEmmissiveMat2);

    scene.primitives ~= Sphere(Vec3f([10.0, 0.0, 4.0]), 1.5f, mirrorMat);
    scene.primitives ~= Sphere(Vec3f([12.0, 0.0, 0.0]), 2.5f, diffuseGreyMat);
    scene.primitives ~= Sphere(Vec3f([10.0, 0.0, -5.0]), 3.5f, diffuseRedMat);

    Light skyLight = {
        type: LightType.SKY,
        sky: SkyLight(skyMaterial)
    };
    scene.lights ~= skyLight;

    scene.process();

    return scene;
}