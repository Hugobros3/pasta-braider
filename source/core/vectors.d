import std.algorithm.iteration;
import std.algorithm.mutation;
import std.math;
import std.array;
import std.range;

/// Fully generic vector types !
struct Vec(int dim, T) {
    static assert(dim > 0, "What kind of vector is this even supposed to be");

    /// Actual data container
    T[dim] data;

    alias Self = Vec!(dim, T);

    /// Scalar multiplication
    pure Self opBinary(string s)(T scalar) if (s == "*") {
        Self newVec;
        newVec.data = map!((T a) => a * scalar)(data[]).array();
        return newVec;
    }

    /// Dot product
    pure Self opBinary(string s)(Self rhs) if (s == "*") {
        Self newVec;
        newVec.data = zip(this.data[], rhs.data[]).map!(tuple => tuple[0] * tuple[1]).array();
        return newVec;
    }

    pure T lengthSquared() {
        return data.fold!((acc, value) => acc + value * value);
    }

    pure T length() {
        return sqrt(this.lengthSquared());
    }

    pure Self normalize() {
        T invLength = T(1.0) / this.length();
        return this * invLength;
    }

    /// Returns a reference to the first component of the vector
    pure ref T x()() if(dim >= 1) {
        return data[0];
    }

    /// Returns a reference to the second component of the vector
    pure ref T y()() if(dim >= 2) {
        return data[1];
    }

    /// Returns a reference to the third component of the vector
    pure ref T z()() if(dim >= 3) {
        return data[2];
    }

    /// Returns a reference to the fourth component of the vector
    pure ref T w()() if(dim >= 4) {
        return data[3];
    }

    this(T scalar) {
        data[].fill(scalar);
    }

    this(T[dim] values) {
        this.data = values;
    }
}

alias Vec2f = Vec!(2, float);
alias Vec3f = Vec!(3, float);
alias Vec4f = Vec!(4, float);

//alias Vec3i = Vec!(3, int);
//alias Vec0f = Vec!(0, float);
alias Vec3d = Vec!(3, double);