import std.algorithm.iteration;
import std.algorithm.mutation;
import std.algorithm.searching;
//import std.math;
import std.array;
import std.range;
import std.stdio;
import std.encoding;

import core.simd;
import ldc.simd;

version(D_SIMD) {
    pragma(msg, "yes");
}

pragma(LDC_intrinsic, "llvm.sqrt.f32")
  @nogc pure float sqrt(float);

/// Fully generic vector types !
struct Vec(int dim, T) {
    static assert(dim > 0, "What kind of vector is this even supposed to be");

    /// Actual data container
    static if(dim >= 2 && dim <= 4 && is(T == float)) {
        //float[4] data;
        float4 data;
        static immutable bool is_simd = true;
        //alias data = _data.ptr;
        //T[dim] data;
    } else {
        T[dim] data;
        static immutable bool is_simd = false;
    }

    alias Self = Vec!(dim, T);

    /// Scalar multiplication
    pragma(inline, true)
    @nogc pure Self opBinary(string s)(const T scalar) const if (s == "*") {
        Self newVec;
        static if(is_simd) {
            newVec.data = data * scalar;
        } else {
            static foreach(i; 0 .. dim) {
                newVec.data[i] = data[i] * scalar;
            }
        }
        return newVec;
    }

    private static immutable string[] vectorOperators = ["*", "/", "+", "-"];
    /// Traditional operations extended to vectors
    pragma(inline, true)
    @nogc pure Self opBinary(string s)(const Self rhs) const if (vectorOperators.canFind(s)) {
        Self newVec;
        static if(is_simd) {
            auto a = data;
            auto b = rhs.data;
            newVec.data = mixin("a" ~ s ~ "b");
        } else {
            static foreach(i; 0 .. dim) {
                {
                T a = data[i];
                T b = rhs.data[i];
                newVec.data[i] = mixin("a" ~ s ~ "b");
                }
            }
        }
        
        //copy(zip(this.data[], rhs.data[]).map!(tuple => mixin("tuple[0]" ~ s ~ "tuple[1]")), newVec.data[]);
        return newVec;
    }

    /// Vector negation
    pragma(inline, true)
    @nogc pure Self opUnary(string s)() const if (s == "-") {
        Self newVec;

        static if(is_simd) {
            newVec.data = -data;
        } else {
            static foreach(i; 0 .. dim) {
                newVec.data[i] = -data[i];
            }
        }
        //copy(this.data[].map!(a => -a), newVec.data[]);
        return newVec;
    }

    pragma(inline, true)
    @nogc pure T lengthSquared() const {
        T acc = T(0);

        static if(is_simd) {
            auto xd = data * data;
            static foreach(i; 0 .. dim) {
                acc += xd[i];
            }
        } else {
            static foreach(i; 0 .. dim) {
                acc += data[i] * data[i];
            }
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
        static if(is_simd) {
            static foreach(i; 0 .. dim ){
                this.data[i] = values[i];
            }
        } else {
            this.data = values;
        }
    }
}

/// Dot product
@nogc pure T dot(int dim, T)(const ref Vec!(dim, T) lhs, const ref Vec!(dim, T) rhs) {
    T acc = T(0);
    static if(Vec!(dim, T).is_simd) {
        auto xd = lhs.data * rhs.data;
        static foreach(i; 0 .. dim) {
            acc += xd[i];
        }
    } else {
        static foreach(i; 0 .. dim) {
            acc += lhs.data[i] * rhs.data[i];
        }
    }
    return acc;
    //return (lhs * rhs).data.fold!((T acc, T value) => acc + value);
}

/// Cross product (3d specialized version)
pragma(inline, true)
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