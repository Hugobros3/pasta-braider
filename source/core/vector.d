import std.algorithm.iteration;
import std.algorithm.mutation;
import std.algorithm;
import std.math;
import std.array;
import std.range;
import std.stdio;
import std.encoding;

/// Fully generic vector types !
struct Vec(int dim, T) {
    static assert(dim > 0, "What kind of vector is this even supposed to be");

    /// Actual data container
    T[dim] data;

    alias Self = Vec!(dim, T);

    /// Scalar multiplication
    pure Self opBinary(string s)(const T scalar) if (s == "*") {
        Self newVec;
        newVec.data = map!((T a) => a * scalar)(data[]).array();
        return newVec;
    }

    /// Dot product
    pure Self opBinary(string s)(const Self rhs) const if (s == "*") {
        Self newVec;
        newVec.data = zip(this.data[], rhs.data[]).map!(tuple => tuple[0] * tuple[1]).array();
        return newVec;
    }

    /// Vector add
    pure Self opBinary(string s)(const Self rhs) const if (s == "+") {
        Self newVec;
        newVec.data = zip(this.data[], rhs.data[]).map!(tuple => tuple[0] + tuple[1]).array();
        return newVec;
    }

    /// Vector sub
    pure Self opBinary(string s)(const Self rhs) const if (s == "-") {
        Self newVec;
        newVec.data = zip(this.data[], rhs.data[]).map!(tuple => tuple[0] - tuple[1]).array();
        return newVec;
    }

    /// Vector negation
    pure Self opUnary(string s)() const if (s == "-") {
        Self newVec;
        newVec.data =  map!((T a) => -a)(data[]).array();
        return newVec;
    }

    pure T lengthSquared() {
        return data.fold!((acc, value) => acc + value * value);
    }

    pure T length()() if(__traits(isFloating, T)) {
        return sqrt(this.lengthSquared());
    }

    pure T distanceSquared(Self rhs) {
        return (this - rhs).lengthSquared();
    }

    pure Self normalize()() if(__traits(isFloating, T)) {
        T invLength = T(1.0) / this.length();
        return this * invLength;
    }

    static immutable string[] shorthands = ["x", "y", "z", "w"];
    static immutable char[] shorthandsChar = ['x', 'y', 'z', 'w'];

    pure static bool isShortHandName(string s) {
        foreach(e ; s) {
            if(!shorthandsChar.canFind(e)) {
                return false;
            }
        }
        return true;
    }

    /*pure const auto opDispatch(string s)() if(isShortHandName(s)) {
        if(s.length > 1) {
            Vec!(s.length, T) target;
            foreach(i, e; s) {
                int i2 = cast(int)(shorthandsChar.countUntil(e));
                target.data[i] = data[i2];
            }
            return target;
        } else {
            int i = cast(int)(shorthands.countUntil(s));
            float target = data[i];
            return target;
        }
    }*/

    /// Const access over one named member
    pure const auto opDispatch(string s)() if(isShortHandName(s) && s.length == 1) {
        int i = cast(int)(shorthands.countUntil(s));
        return data[i];
    }

    /// Compile time swizzling
    pure const auto opDispatch(string s)() if(isShortHandName(s) && s.length > 1) {
        Vec!(s.length, T) target;
        foreach(i, e; s) {
            int i2 = cast(int)(shorthandsChar.countUntil(e));
            target.data[i] = data[i2];
        }
        return target;
    }

    /// Mutable access over one named member
    pure ref auto opDispatch(string s)() if(isShortHandName(s) && s.length == 1) {
        if(s.length == 1) {
            int i = cast(int)(shorthands.countUntil(s));
            return data[i];
        }
    }

    this(T scalar) {
        data[].fill(scalar);
    }

    this(T[dim] values) {
        this.data = values;
    }
}

pure static T dot(int dim, T)(const ref Vec!(dim, T) lhs, const ref Vec!(dim, T) rhs) {
    return zip(lhs.data[], rhs.data[]).map!(tuple => tuple[0] * tuple[1]).fold!((acc, value) => acc + value * value);
}

/// Cross product
Vec!(3, T) cross(T)(const ref Vec!(3, T) a, const ref Vec!(3, T) b) {
    const float aa = a.y();
    Vec!(3, T) vec = [
                    a.y * b.z - a.z * b.y,
                    a.z * b.x - a.x * b.z,
                    a.x * b.y - a.y * b.x];
    return vec;
}

alias Vec2f = Vec!(2, float);
alias Vec3f = Vec!(3, float);
alias Vec4f = Vec!(4, float);

alias Vec2i = Vec!(2, int);
alias Vec3i = Vec!(3, int);