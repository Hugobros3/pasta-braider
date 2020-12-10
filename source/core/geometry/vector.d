import std.algorithm.iteration;
import std.algorithm.mutation;
import std.algorithm.searching;
//import std.math;
import std.array;
import std.range;
import std.stdio;
import std.encoding;
import std.algorithm.comparison : smax = max, smin = min;

import core.simd;

import fast_math;

/// Fully generic vector types !
struct Vec(int dim, T) {
    static assert(dim > 0, "What kind of vector is this even supposed to be");

    T[dim] data;

    alias Self = Vec!(dim, T);

    /// Scalar multiplication
    pragma(inline, true)
    @nogc pure Self opBinary(string s)(const T scalar) const if (s == "*") {
        Self newVec;
        static foreach(i; 0 .. dim) {
            newVec.data[i] = data[i] * scalar;
        }
        return newVec;
    }
    pragma(inline, true)
    @nogc pure Self opBinaryRight(string s)(const T scalar) const if (s == "*") {
        Self newVec;
        static foreach(i; 0 .. dim) {
            newVec.data[i] = data[i] * scalar;
        }
        return newVec;
    }

    private static immutable string[] vectorOperators = ["*", "/", "+", "-", "%"];
    /// Traditional operations extended to vectors
    pragma(inline, true)
    @nogc pure Self opBinary(string s)(const Self rhs) const if (vectorOperators.canFind(s)) {
        Self newVec;
        static foreach(i; 0 .. dim) {{
            T a = data[i];
            T b = rhs.data[i];
            newVec.data[i] = mixin("a" ~ s ~ "b");
        }}
        
        //copy(zip(this.data[], rhs.data[]).map!(tuple => mixin("tuple[0]" ~ s ~ "tuple[1]")), newVec.data[]);
        return newVec;
    }

    /// Vector negation
    pragma(inline, true)
    @nogc pure Self opUnary(string s)() const if (s == "-") {
        Self newVec;
        static foreach(i; 0 .. dim) {
            newVec.data[i] = -data[i];
        }
        //copy(this.data[].map!(a => -a), newVec.data[]);
        return newVec;
    }

    pragma(inline, true)
    @nogc pure T lengthSquared() const {
        T acc = T(0);
        static foreach(i; 0 .. dim) {
            acc += data[i] * data[i];
        }
        return acc;
        //return data.fold!((acc, value) => acc + value * value)(cast(T)0);
    }

    pragma(inline, true)
    @nogc pure T length()() const if(__traits(isFloating, T)) {
        return sqrt(this.lengthSquared());
    }

    pragma(inline, true)
    @nogc pure T distanceSquared(Self rhs) const {
        return (this - rhs).lengthSquared();
    }

    pragma(inline, true)
    @nogc pure Self normalize()() const if(__traits(isFloating, T)) {
        T invLength = T(1.0) / this.length();
        return this * invLength;
    }

    private static immutable char[] shorthandsChar = ['x', 'y', 'z', 'w'];

    // Not non-gc but it doesn't matter since this is only ever called at compile time!
    private pure static bool isSwizzleName(string s)() {
        static foreach(e ; s) {
            if(swizzleIndex(e) == -1) {
                return false;
            }
        }
        return true;
    }

    private pure static int swizzleIndex(char c) {
        static foreach(i, e ; shorthandsChar) {
            if(e == c) {
                return cast(int)i;
            }
        }
        return -1;
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
    pragma(inline, true)
    @nogc pure const auto opDispatch(string s)() if(isSwizzleName!(s) && s.length == 1) {
        immutable int i = swizzleIndex(s[0]);
        return data[i];
    }

    /// Compile time swizzling
    pragma(inline, true)
    @nogc pure const auto opDispatch(string s)() if(isSwizzleName!(s) && s.length > 1) {
        Vec!(s.length, T) target;
        static foreach (int i; 0..s.length) {
            target.data[i] = data[swizzleIndex(s[i])];
        }
        return target;
    }

    /// Mutable access over one named member
    pragma(inline, true)
    @nogc pure ref auto opDispatch(string s)() if(isSwizzleName!(s) && s.length == 1) {
        if(s.length == 1) {
            immutable int i = swizzleIndex(s[0]);
            return data[i];
        }
    }

    this(T scalar) {    
        data[].fill(scalar);
    }

    this(immutable T[dim] values) {
        this.data = values;
    }
}

/// Dot product
pragma(inline, true)
@nogc pure T dot(int dim, T)(const Vec!(dim, T) lhs, const Vec!(dim, T) rhs) {
    T acc = T(0);
    static foreach(i; 0 .. dim) {
        acc += lhs.data[i] * rhs.data[i];
    }
    return acc;
    //return (lhs * rhs).data.fold!((T acc, T value) => acc + value);
}

/// max
pragma(inline, true)
@nogc pure Vec!(dim, T) max(int dim, T)(const Vec!(dim, T) lhs, const Vec!(dim, T) rhs) {
    Vec!(dim, T) target;
    static foreach(i; 0 .. dim) {
        {
        float l = lhs.data[i];
        float r = rhs.data[i];
        target.data[i] = smax(l, r);
        }
    }
    return target;
}
/// min
pragma(inline, true)
@nogc pure Vec!(dim, T) min(int dim, T)(const Vec!(dim, T) lhs, const Vec!(dim, T) rhs) {
    Vec!(dim, T) target;
    static foreach(i; 0 .. dim) {
        target.data[i] = smin(lhs.data[i], rhs.data[i]);
    }
    return target;
}

/// Cross product (3d specialized version)
pragma(inline, true)
@nogc pure Vec3f cross(const Vec3f a, const Vec3f b) {
    Vec3f v = a.yzx * b.zxy - a.zxy * b.yzx;
    Vec3f vec = [
                    a.y * b.z - a.z * b.y,
                    a.z * b.x - a.x * b.z,
                    a.x * b.y - a.y * b.x];
    return v;
}

@nogc pure Vec3f reflect(int dim, T)(const Vec!(dim, T) v, const Vec!(dim, T) n) {
    return n * (dot(n, v) * 2.0f) - v;
}

alias Vec2f = Vec!(2, float);
alias Vec3f = Vec!(3, float);
alias Vec4f = Vec!(4, float);

alias Vec2i = Vec!(2, int);
alias Vec3i = Vec!(3, int);