import std.stdio;
import bbox;
import vectors;

void main()
{
	BBox3f bbox;
	Vec3f vec = ( 0.0f );
	Vec3f vec2 = [ 0.0f, 0.0f, 0.05f ];

	vec.x = 1.0f;
	vec.z = 2.0f;
	
	//vec.w = 4.0;
	writeln(vec.normalize());
	writeln(vec * vec);
	writeln(vec.x());
}
