import std.algorithm.mutation;
import std.algorithm.comparison;
import std.random;
import std.stdio;
import std.string;
import std.conv;
import core.time;

import film;
import color;
import vector;
import camera;
import ray;
import scene;
import algo;

import sphere;

import bindbc.sdl;

class Window : Film!(RGB) {
    private Vec2i _size = [512, 512];
    private RGB[] _pixels;

    private Scene!Sphere scene = new Scene!Sphere();
    private Camera camera;

    this() { 
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

        scene.primitives ~= Sphere(Vec3f([10.0, 0.0, 0.0]), 1.5f);

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

        while (!quit) {
            MonoTime frameStart = MonoTime.currTime;

            clear();
            camera.update();

            immutable @nogc auto algorithm = make_debug_renderer!(RGB, Sphere);
            draw!(algorithm)(this);

            foreach(x ; 0 .. _size.x()) {
                foreach(y ; 0 .. _size.y()) {
                    //ubyte luminance = cast(ubyte)uniform(0, 255);
                    auto rgb = _pixels[((y * _size.x) + x)];

                    buf[((y * _size.x) + x) * 4 + 3] = cast(ubyte)clamp(cast(int)(rgb.x * 255), 0, 255);
                    buf[((y * _size.x) + x) * 4 + 2] = cast(ubyte)clamp(cast(int)(rgb.y * 255), 0, 255);
                    buf[((y * _size.x) + x) * 4 + 1] = cast(ubyte)clamp(cast(int)(rgb.z * 255), 0, 255);
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

@nogc void draw(immutable(RGB function(immutable ref Camera, const Vec2i, Vec2i, const ref Scene!(Sphere)) @nogc) renderer)(Window window) {
    Vec2i viewportSize = window.size();
    immutable Camera imRef = window.camera;
    foreach(x; 0 .. window.size.x) {
        foreach(y; 0 .. window.size.y) {
            window.add(Vec2i([x, y]), renderer(imRef, viewportSize, Vec2i ([x, y]), window.scene) );
        }
    }
}