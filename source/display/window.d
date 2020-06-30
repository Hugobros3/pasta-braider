import std.algorithm.mutation;
import std.algorithm.comparison;
import std.random;
import std.stdio;
import std.string;
import std.conv;
import std.range;
import core.time;
import std.parallelism;

import performance;
import rng;

import film;
import color;
import vector;
import camera;
import ray;
import scene;
import algo;
import material;
import light;

import sphere;

//import pt;
import direct_lighting;

import bindbc.sdl;

class Window : Film!(RGB) {
    private Vec2i _size = [1024, 1024];
    private RGB[] _pixels;

    private Scene!Sphere scene = new Scene!Sphere();
    private Camera camera;

	Material emmissiveMat =      make_diffuse_material!( Vec3f([1.0, 0.5, 0.0]), 10.0f );
	Material veryEmmissiveMat =  make_diffuse_material!( Vec3f([1.0, 0.0, 1.0]), 2.0f );
	Material veryEmmissiveMat2 = make_diffuse_material!( Vec3f([0.0, 1.0, 0.0]), 2.0f );

	Material diffuseRedMat =     make_diffuse_material!( Vec3f([1.0, 0.0, 0.0]), 0.0f );
	Material diffuseGreyMat =    make_diffuse_material!( Vec3f([0.8, 0.8, 0.8]), 0.0f );
	Material skyMaterial =       make_diffuse_material!( Vec3f([0.0f, 0.005f, 0.015f]), 0.0f );

    this() { 
		//defaultPoolThreads(16);

        _pixels = new RGB[_size.x * _size.y];
        SDLSupport ret = loadSDL();
        if(ret != sdlSupport) {
            if(ret == SDLSupport.noLibrary) {
                // SDL shared library failed to load
                throw new Exception("SDL shared Library not found");
            }
            else if(SDLSupport.badLibrary) {
                // One or more symbols failed to load. The likely cause is that the
                // shared library is for a lower version than bindbc-sdl was configured
                // to load (via SDL_201, SDL_202, etc.)
                throw new Exception("Mismatched SDL library version");
            }
        }

        camera.position = Vec3f([0.0, 0.0, 0.0]);
        camera.lookingAt = Vec3f([1.0, 0.0, 0.0]);

        scene.primitives ~= Sphere(Vec3f([10.0, 0.0, -100.0]), 98.5f, &diffuseGreyMat);

        scene.primitives ~= Sphere(Vec3f([12.0, -5.0, 10.0]), 1.5f, &emmissiveMat);

        scene.primitives ~= Sphere(Vec3f([8.5, 0.0, 0.0]), 0.5f, &veryEmmissiveMat);
        scene.primitives ~= Sphere(Vec3f([6.5, 3.0, -1.0]), 0.5f, &veryEmmissiveMat2);

        scene.primitives ~= Sphere(Vec3f([10.0, 4.0, 0.0]), 1.5f, &diffuseRedMat);
        scene.primitives ~= Sphere(Vec3f([12.0, 0.0, 0.0]), 2.5f, &diffuseGreyMat);
        scene.primitives ~= Sphere(Vec3f([10.0, -5.0, 0.0]), 3.5f, &diffuseRedMat);

        scene.addEmmissivePrimitives();

        Light skyLight = {
		    type: LightType.SKY,
		    sky: SkyLight(skyMaterial)
		};
        //scene.lights ~= skyLight;


        /*Light pointLight = {
		    type: LightType.POINT,
		    point: PointLight(veryEmmissiveMat2, Vec3f([8.5, 0.0, 0.0]))
		    };
		scene.lights ~= pointLight;
        Light pointLight2 = {
		    type: LightType.POINT,
		    point: PointLight(veryEmmissiveMat, Vec3f([6.5, 3.0, -1.0]))
		    };
		scene.lights ~= pointLight2;*/

        foreach(primId, primitive; scene.primitives) {
            writeln(primitive);
		}
    }

    void run() {
        SDL_Init(SDL_INIT_VIDEO);
        SDL_Window* window = SDL_CreateWindow("SDL2 Displaying Image", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, _size.x, _size.y, cast(SDL_WindowFlags)(0));
        SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE /*cast(SDL_RendererFlags)(0)*/);

        SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STATIC, _size.x, _size.y );

        ubyte[] buf = new ubyte[_size.x * _size.y * 4];

        bool quit = false;
        SDL_Event event;

		clear();
        int acc = 0;
        while (!quit) {
            MonoTime frameStart = MonoTime.currTime;

            //clear();
            //acc = 0;

            acc++;
            camera.update();

            immutable @nogc auto algorithm = make_direct_lighting_renderer!(RGB, Sphere);
            draw!(algorithm)(this);

            float invAcc = 1.0f / acc;
        	
            auto xr = iota(0, size.x);
            foreach(x ; parallel(xr)) {
                foreach(y ; 0 .. _size.y()) {
                    //ubyte luminance = cast(ubyte)uniform(0, 255);
                    auto rgb = _pixels[((y * _size.x) + x)];

                    buf[((y * _size.x) + x) * 4 + 3] = cast(ubyte)clamp(cast(int)(sqrt(rgb.x * invAcc) * 255), 0, 255);
                    buf[((y * _size.x) + x) * 4 + 2] = cast(ubyte)clamp(cast(int)(sqrt(rgb.y * invAcc) * 255), 0, 255);
                    buf[((y * _size.x) + x) * 4 + 1] = cast(ubyte)clamp(cast(int)(sqrt(rgb.z * invAcc) * 255), 0, 255);
                    buf[((y * _size.x) + x) * 4 + 0] = 0x00;
                }
            }

            SDL_UpdateTexture(texture, null, cast(const(void*))(buf.ptr), cast(int)(size.x() * uint.sizeof));

            //SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, null, null);
            SDL_RenderPresent(renderer);

            MonoTime frameDone = MonoTime.currTime;
            Duration frameDuration = frameDone - frameStart;
            long usecs = frameDuration.total!"usecs"();
            float fps = 1000_000.0 / cast(double)(usecs);
            const string title = ("FPS: " ~ to!string(fps));
            SDL_SetWindowTitle(window, toStringz(title) );

            while(SDL_PollEvent(&event)) {
                switch (event.type) {
                    case SDL_QUIT:
                        quit = true;
                        break;
                    default: break;
                }
            }
        }

        SDL_DestroyTexture(texture);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
    }

    final override void clear() {
        _pixels[].fill(RGB(0.0f));
    }

    pragma(inline, true)
    final override Vec2i size() {
        return _size;
    }

    pragma(inline, true)
    final override void add(Vec2i position, RGB contribution) {
        _pixels[position.x * size.y + position.y] = _pixels[position.x * size.y + position.y] + contribution;
    }
}

void draw(immutable(RGB function(immutable ref Camera, const Vec2i, Vec2i, const ref Scene!(Sphere)) @nogc) renderer)(Window window) {
    Vec2i viewportSize = window.size();
    immutable Camera imRef = window.camera;
	auto xr = iota(0, window.size.x);
    foreach(x; parallel(xr, 1)) {
    //foreach(x; xr) {
		seedRng();
        auto yr = iota(0, window.size.y);
        foreach(y; yr) {
            immutable auto spp = 1;
            RGB samples = 0.0;
            foreach(sample; 0 .. spp) {
                samples = samples + renderer(imRef, viewportSize, Vec2i ([x, y]), window.scene) * (1.0 / spp);
			}
            window.add(Vec2i([x, y]), samples );
        }   
    }
}