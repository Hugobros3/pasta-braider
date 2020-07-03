import scene;
import sphere;

import material;
import vector;
import light;

private	immutable { 
	Material emmissiveMat =      make_diffuse_material!( Vec3f([1.0, 1.0, 1.0]), 100.0f );

	Material diffuseGreyMat =    make_diffuse_material!( Vec3f([1.0, 1.0, 1.0]), 0.0f );
	Material diffuseRedMat =     make_diffuse_material!( Vec3f([1.0, 0.0, 0.0]), 0.0f );
	Material diffuseGreenMat =   make_diffuse_material!( Vec3f([0.0, 1.0, 0.0]), 0.0f );

	Material skyMaterial =       make_diffuse_material!( Vec3f([0.0f, 0.005f, 0.015f]), 0.0f ); 

	Material mirrorMat =         make_mirror_material!( Vec3f([1.0, 1.0, 1.0]));
}

Scene!Sphere make_cornell_balls_scene() {
	auto scene = new Scene!Sphere();

	// walls
	scene.primitives ~= Sphere(Vec3f([10.0, -1000.0, 0.0]), 990.0f, &diffuseGreyMat);
	scene.primitives ~= Sphere(Vec3f([10.0, 1000.0, 0.0]), 990.0f, &diffuseGreyMat);
	scene.primitives ~= Sphere(Vec3f([1010.0, 0.0, 0]), 990.0f, &diffuseGreyMat);
	scene.primitives ~= Sphere(Vec3f([10.0, 0, -1000.0]), 990.0f, &diffuseGreenMat);
	scene.primitives ~= Sphere(Vec3f([10.0, 0, 1000.0]), 990.0f, &diffuseRedMat);

	// light
	scene.primitives ~= Sphere(Vec3f([10.0, 11.0, 0.0]), 1.5f, &emmissiveMat);

	// object
	scene.primitives ~= Sphere(Vec3f([12.0, 0.0, 3.0]), 2.5f, &diffuseGreyMat);

	// mirror ball
	scene.primitives ~= Sphere(Vec3f([8.0, -5.0, 4.0]), 2.0f, &mirrorMat);

	Light skyLight = {
		type: LightType.SKY,
		sky: SkyLight(skyMaterial)
	};
	//scene.lights ~= skyLight;

	scene.preProcessLights();

	return scene;
}