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

void load(string file) {
	import std.string;
	import std.conv;
	const aiScene* scene = aiImportFile( toStringz(file), 
										 aiPostProcessSteps.CalcTangentSpace        | 
										aiPostProcessSteps.Triangulate            |
										aiPostProcessSteps.JoinIdenticalVertices  |
										aiPostProcessSteps.SortByPType);
	// If the import failed, report it
	if( !scene) {
		string errstr = fromStringz(aiGetErrorString()).idup()	;
		throw new Exception( errstr );
		//return false;
	}

	for(int i = 0; i < scene.mNumMeshes; i++) {
		const aiMesh* mesh = scene.mMeshes[i];
		const aiMaterial* material = scene.mMaterials[mesh.mMaterialIndex];
		printf("vertices: %d \n", mesh.mNumVertices);

		//const aiMaterialProperty* prop;
		//aiGetMaterialProperty(material, toStringz("?mat.name"), 0, 0, &prop);
		aiString prop;
		aiGetMaterialString(material, toStringz("?mat.name"), 0, 0, &prop);
		string mah_string = prop.data[0 .. prop.length].idup;

		writeln("material name: ", mah_string);
	}
}