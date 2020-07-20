import vector;

struct Mat4f {
	float[4][4] data = identity.dup;

	void loadIdentity() {
		data = identity;
	}

	immutable static float[4][4] identity = [ 
		[ 1, 0, 0, 0],
		[ 0, 1, 0, 0],
		[ 0, 0, 1, 0],
		[ 0, 0, 0, 1],
	];

	pragma(inline, true)
	@nogc pure Mat4f opBinary(string s)(const Mat4f rhs) const if (s == "*") {
		alias lhs = this;
		Mat4f result;
		foreach(i; 0 .. 4) {
			foreach(j; 0 .. 4) {
				float acc = 0.0;
				foreach(t; 0 .. 4) {
					acc += lhs.data[i][t] * rhs.data[t][j];
					//acc += lhs.data[t][i] * rhs.data[j][t];
				}
				result.data[i][j] = acc;
			}
		}
		return result;
	}

	pragma(inline, true)
	@nogc pure Vec4f opBinary(string s)(const Vec4f rhs) const if (s == "*") {
		alias lhs = this;
		Vec4f result;

		foreach(component; 0 .. 4) {
			float acc = 0.0;
			foreach(n; 0 .. 4) {
				acc += lhs.data[component][n] * rhs.data[n];
				//acc += lhs.data[n][component] * rhs.data[n];
			}
			result.data[component] = acc;
		}
		return result;
	}

}