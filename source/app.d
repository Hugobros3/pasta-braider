import std.stdio;
import std.algorithm.iteration;
import std.algorithm.mutation;
import std.algorithm;
import std.regex;
import bbox;
import vector;

static immutable auto shorthandsRegex = regex("^([xyzw]+)$");

bool compileTimeMatch(string s)() {
	return matchFirst(s, shorthandsRegex).length() > 0;
}

void main() {
	Vec3f vec = ( 0.0f );
	Vec3f vec2 = [ 0.0f, 0.0f, 0.05f ];
	vec.x = 1.0f;
	vec.z = 2.0f;
	writeln(vec.zzzzz);

	//writeln(vec.opDispatch!("xy")());
	Vec3f r = vec.opDispatch!("xyz")();
	writeln(r);
	
	//auto objects = [1, 2, 3];
	//auto refs = objects.map!(function(ref a) return ).array();

	//vec.w = 4.0;
	writeln(vec.normalize());
	writeln(-vec);
	writeln(vec * vec);
	writeln("dot: ", dot(vec, vec));
	//writeln(vec.cross(vec));
	writeln(vec.x());
	
	writeln(compileTimeMatch!("x")());
	writeln(matchFirst("x", shorthandsRegex).length() > 0);
}