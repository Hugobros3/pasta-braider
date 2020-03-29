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
    @nogc pure Self opBinary(string s)(const T scalar) const if (s == "*") {
        Self newVec;
        copy(data[].zip(scalar.repeat).map!(a => a[0] * a[1]), newVec.data[]);
        return newVec;
    }

    private static immutable string[] vectorOperators = ["*", "/", "+", "-"];
    /// Traditional operations extended to vectors
    @nogc pure Self opBinary(string s)(const Self rhs) const if (vectorOperators.canFind(s)) {
        Self newVec;
        copy(zip(this.data[], rhs.data[]).map!(tuple => mixin("tuple[0]" ~ s ~ "tuple[1]")), newVec.data[]);
        return newVec;
    }

    /// Vector negation
    @nogc pure Self opUnary(string s)() const if (s == "-") {
        Self newVec;
        copy(this.data[].map!(a => -a), newVec.data[]);
        return newVec;
    }

    @nogc pure T lengthSquared() const {
        return data.fold!((acc, value) => acc + value * value);
    }

    @nogc pure T length()() const if(__traits(isFloating, T)) {
        return sqrt(this.lengthSquared());
    }

    @nogc pure T distanceSquared(Self rhs) const {
        return (this - rhs).lengthSquared();
    }

    @nogc pure Self normalize()() const if(__traits(isFloating, T)) {
        T invLength = T(1.0) / this.length();
        return this * invLength;
    }

    private static immutable char[] shorthandsChar = ['x', 'y', 'z', 'w'];

    // Not non-gc but it doesn't matter since this is only ever called at compile time!
    private pure static bool isSwizzleName(string s) {
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
    @nogc pure const auto opDispatch(string s)() if(isSwizzleName(s) && s.length == 1) {
        int i = cast(int)(shorthandsChar.countUntil(s[0]));
        return data[i];
    }

    /// Compile time swizzling
    @nogc pure const auto opDispatch(string s)() if(isSwizzleName(s) && s.length > 1) {
        Vec!(s.length, T) target;
        foreach(i, e; s) {
            int i2 = cast(int)(shorthandsChar.countUntil(e));
            target.data[i] = data[i2];
        }
        return target;
    }

    /// Mutable access over one named member
    @nogc pure ref auto opDispatch(string s)() if(isSwizzleName(s) && s.length == 1) {
        if(s.length == 1) {
            int i = cast(int)(shorthandsChar.countUntil(s[0]));
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

/// Dot product
@nogc pure T dot(int dim, T)(const ref Vec!(dim, T) lhs, const ref Vec!(dim, T) rhs) {
    return (lhs * rhs).data.reduce!((T acc, T value) => acc + value * value);
}

/// Cross product (3d specialized version)
@nogc pure Vec!(3, T) cross(T)(const ref Vec!(3, T) a, const ref Vec!(3, T) b) {
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