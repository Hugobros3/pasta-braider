import scene;
import triangle;

import material;
import vector;
import matrix;
import light;

import std.stdio;
import bindbc.assimp;

private { 
    Material emmissiveMat =      make_diffuse_material!( Vec3f([1.0, 1.0, 1.0]), 100.0f );

    Material errorMat =          make_diffuse_material!( Vec3f([1.0, 0.0, 1.0]), 0.0f );

    Material diffuseGreyMat =    make_diffuse_material!( Vec3f([0.8, 0.8, 0.8]), 0.0f );
    Material diffuseRedMat =     make_diffuse_material!( Vec3f([1.0, 0.0, 0.0]), 0.0f );
    Material diffuseGreenMat =   make_diffuse_material!( Vec3f([0.0, 1.0, 0.0]), 0.0f );

    Material skyMaterial =       make_diffuse_material!( Vec3f([0.0f, 0.05f, 0.15f]), 0.5f ); 

    Material mirrorMat =         make_mirror_material!( Vec3f([1.0, 1.0, 1.0]));
}

Scene!Triangle make_cornell_box_scene() {
	import std.string;
	import std.conv;

    auto scene = new Scene!Triangle();

	const aiScene* aiScene = aiImportFile( toStringz("scenes/cornell.glb"), 
										  aiPostProcessSteps.CalcTangentSpace       | 
										  aiPostProcessSteps.Triangulate            |
										  aiPostProcessSteps.JoinIdenticalVertices  |
										  aiPostProcessSteps.SortByPType);
	if(!aiScene) {
		string errstr = fromStringz(aiGetErrorString()).idup()	;
		throw new Exception(errstr);
	}

	void visitNode(const aiNode* node, Mat4f parent_transform) {
		Mat4f local_transform;
		local_transform.data = *(cast(float[4][4]*)&(node.mTransformation));
		Mat4f matrix = parent_transform * local_transform;
		writeln(matrix);
		
		for(int m = 0; m < node.mNumMeshes; m++) {
			const aiMesh* mesh = aiScene.mMeshes[node.mMeshes[m]];
			const aiMaterial* material = aiScene.mMaterials[mesh.mMaterialIndex];

			//const aiMaterialProperty* prop;
			//aiGetMaterialProperty(material, toStringz("?mat.name"), 0, 0, &prop);
			aiString prop;
			aiGetMaterialString(material, toStringz("?mat.name"), 0, 0, &prop);
			string mat_string = prop.data[0 .. prop.length].idup;

			const(Material*) pick() {
				switch(mat_string) {
					case "grey": return &diffuseGreyMat;
					case "red": return &diffuseRedMat;
					case "green": return &diffuseGreenMat;
					case "light": return &emmissiveMat;
					case "mirror": return &mirrorMat;
						default: return &errorMat;
				}
			}

			writeln("material name: ", mat_string);
			const Material* mptr = pick();

			printf("vertices: %d \n", mesh.mNumVertices);
			for(int f = 0; f < mesh.mNumFaces; f++) {
				const aiFace face = mesh.mFaces[f];
				assert(3 == face.mNumIndices);

				Vec3f load_vertex(uint indice) {
					const aiVector3D vec = mesh.mVertices[indice];
					Vec4f vtx = [ vec.x, vec.y, vec.z, 1.0f ];
					Vec4f transformedVtx = matrix * vtx;
					//writeln(vtx);
					//writeln(matrix);
					//writeln(transformedVtx);
					transformedVtx = transformedVtx * (1.0 / transformedVtx.w);
					//writeln(transformedVtx);
					return transformedVtx.xyz;
				}
				
				Vec3f load_normal(uint indice) {
					const aiVector3D vec = mesh.mNormals[indice];
					Vec4f vtx = [ vec.x, vec.y, vec.z, 0.0f ];
					Vec4f transformedVtx = matrix * vtx;
					//writeln(vtx);
					//writeln(matrix);
					//writeln(transformedVtx);
					//transformedVtx = transformedVtx * (1.0 / transformedVtx.w);
					//writeln(transformedVtx);
					return transformedVtx.xyz.normalize();
				}

				Vec3f v0 = load_vertex(face.mIndices[0]);
				Vec3f v1 = load_vertex(face.mIndices[1]);
				Vec3f v2 = load_vertex(face.mIndices[2]);

				Vec3f n0 = load_normal(face.mIndices[0]);
				Vec3f n1 = load_normal(face.mIndices[1]);
				Vec3f n2 = load_normal(face.mIndices[2]);
				Vec3f n = (n0 + n1 + n2) * (1.0 / 3.0);

				Triangle tri = Triangle(v0, v1, v2, n, mptr);

				scene.primitives ~= tri;
			}
		}

		foreach(c; 0 .. node.mNumChildren) {
			visitNode(node.mChildren[c], matrix);
		}
	}

	Mat4f base_matrix;
	base_matrix.data = [ 
		[ -1, 0, 0, 0],
		[ 0, 1, 0, 0],
		[ 0, 0, 1, 0],
		[ 0, 0, 0, 1],
	]; 
	visitNode(aiScene.mRootNode, base_matrix);

    //scene.primitives ~= Sphere(Vec3f([10.0, -1000.0, 0.0]), 990.0f, &diffuseGreyMat);

	Light skyLight = {
	type: LightType.SKY,
	sky: SkyLight(skyMaterial)
    };
    scene.lights ~= skyLight;

    scene.preProcessLights();

    return scene;
}