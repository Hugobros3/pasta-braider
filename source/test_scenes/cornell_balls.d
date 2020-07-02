import scene;
import sphere;

import material;
import vector;
import light;

private	immutable { 
	Material emmissiveMat =      make_diffuse_material!( Vec3f([1.0, 1.0, 1.0]), 100.0f );

	Material diffuseGreyMat =    make_diffuse_material!( Vec3f([0.8, 0.8, 0.8]), 0.0f );
	Material diffuseRedMat =     make_diffuse_material!( Vec3f([1.0, 0.0, 0.0]), 0.0f );
	Material diffuseGreenMat =   make_diffuse_material!( Vec3f([0.0, 1.0, 0.0]), 0.0f );

	Material skyMaterial =       make_diffuse_material!( Vec3f([0.0f, 0.005f, 0.015f]), 0.0f ); 
}

Scene!Sphere make_cornel_balls_scene() {
	auto scene = new Scene!Sphere();

	// walls
	scene.primitives ~= Sphere(Vec3f([10.0, 0.0, -1000.0]), 990.0f, &diffuseGreyMat);
	scene.primitives ~= Sphere(Vec3f([10.0, 0.0, 1000.0]), 990.0f, &diffuseGreyMat);
	scene.primitives ~= Sphere(Vec3f([10.0 + 1000.0, 0.0, 0]), 990.0f, &diffuseGreyMat);
	scene.primitives ~= Sphere(Vec3f([10.0, -1000.0, 0]), 990.0f, &diffuseGreenMat);
	scene.primitives ~= Sphere(Vec3f([10.0, 1000.0, 0]), 990.0f, &diffuseRedMat);

	// light
	scene.primitives ~= Sphere(Vec3f([10.0, 0.0, 11.0]), 1.5f, &emmissiveMat);

	// object
	scene.primitives ~= Sphere(Vec3f([12.0, 3.0, 0.0]), 2.5f, &diffuseGreyMat);

	scene.addEmmissivePrimitives();

	Light skyLight = {
		type: LightType.SKY,
		sky: SkyLight(skyMaterial)
	};
	//scene.lights ~= skyLight;

	return scene;
}