import scene;
import triangle;

import material;
import vector;
import matrix;
import light;

import std.stdio;

import bindbc.assimp;
import loader = bindbc.loader.sharedlib;

void load_assimp() {
	AssimpSupport ret;
	version(Windows) { ret = loadAssimp("assimp.dll"); }
	else { ret = loadAssimp(); }

	foreach(info; loader.errors) {
		printf(info.error);
		printf(info.message);
	}	

	if(ret == AssimpSupport.noLibrary) {
		throw new Exception("couldn't find assimp");
	}
	else if(ret == AssimpSupport.badLibrary) {
		throw new Exception("couldn't load assimp");
	} else {
		printf("Assimp works !\n");
	}
}

Scene!Triangle load_tri_scene(string filename) {
    Material skyMaterial =       make_diffuse_material( Vec3f([0.0f, 0.05f, 0.15f]), 1.15f ); 

    Material mirrorMat =         make_mirror_material( Vec3f([1.0, 1.0, 1.0]));

	import std.string;
	import std.conv;

    auto scene = new Scene!Triangle();

	const aiScene* aiScene = aiImportFile( toStringz(filename), 
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
			const aiMesh* aiMesh = aiScene.mMeshes[node.mMeshes[m]];
			const aiMaterial* aiMaterial = aiScene.mMaterials[aiMesh.mMaterialIndex];

			//const aiMaterialProperty* prop;
			//aiGetMaterialProperty(material, toStringz("?mat.name"), 0, 0, &prop);
			aiString prop;
			aiGetMaterialString(aiMaterial, toStringz("?mat.name"), 0, 0, &prop);
			string mat_string = prop.data[0 .. prop.length].idup;

			//float[3] diffuseColor;
			//uint diffuseLength = 3;
			//aiGetMaterialFloatArray(aiMaterial, toStringz("$clr.diffuse"), 0, 0, &diffuseColor[0], &diffuseLength);
			//writeln("material color: ", diffuseColor[0 .. diffuseLength], "l=", diffuseLength);

			aiColor4D aiDiffuseColor;
			aiGetMaterialColor(aiMaterial, toStringz("$clr.diffuse"), 0, 0, &aiDiffuseColor);
			Vec3f diffuseColor = Vec3f([aiDiffuseColor.r, aiDiffuseColor.g, aiDiffuseColor.b]);
			writeln("material color: ", diffuseColor);

			aiColor4D aiEmissionColor;
			aiGetMaterialColor(aiMaterial, toStringz("$clr.emissive"), 0, 0, &aiEmissionColor);
			Vec3f emissionColor = Vec3f([aiEmissionColor.r, aiEmissionColor.g, aiEmissionColor.b]);
			writeln("emission color: ", emissionColor);

			Material pick() {
				switch(mat_string) {
					case "mirror": return mirrorMat;
						/*case "grey": return &diffuseGreyMat;
						case "red": return &diffuseRedMat;
						case "green": return &diffuseGreenMat;
						case "light": return &emmissiveMat;
						default: return &errorMat;*/
					default: if(emissionColor.length() == 0.0)
						return make_diffuse_material(diffuseColor, 0.0f);
					else
						return make_diffuse_material(emissionColor, 1.0f);
				}
			}
			Material material = pick();

			writeln("material name: ", mat_string);
			writeln("material: ", material.bsdf, material.emission);

			printf("vertices: %d \n", aiMesh.mNumVertices);
			for(int f = 0; f < aiMesh.mNumFaces; f++) {
				const aiFace face = aiMesh.mFaces[f];
				assert(3 == face.mNumIndices);

				Vec3f load_vertex(uint indice) {
					const aiVector3D vec = aiMesh.mVertices[indice];
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
					const aiVector3D vec = aiMesh.mNormals[indice];
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

				Triangle tri = Triangle(v0, v1, v2, n, material);

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

	Light skyLight = {
	type: LightType.SKY,
	sky: SkyLight(skyMaterial)
    };
    scene.lights ~= skyLight;

    scene.process();

    return scene;
}