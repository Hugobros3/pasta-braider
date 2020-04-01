import std.algorithm.mutation;
import std.algorithm.comparison;
import std.random;

import film;
import color;
import vector;
import camera;
import ray;

import bindbc.sdl;

@nogc RGB render2(Window film, Vec2i pos) { 
    //Ray ray = generateRay(film.camera, film.size(), pos);
    return RGB([0.5f, 1.0f, 0.0f]);
}

class Window : Film!(RGB) {
    private Vec2i _size = [1024, 1024];
    private RGB[] _pixels;

    private Camera camera;

    immutable RGB delegate(Film!RGB, Vec2i) drawCmd;

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

        /*camera = Camera {
            position: Vec3f([0.0, 0.0, 0.0]),
            lookingAt: Vec3f([1.0, 0.0, 0.0])
        };*/
        camera.position = Vec3f([0.0, 0.0, 0.0]);
        camera.lookingAt = Vec3f([1.0, 0.0, 0.0]);

        drawCmd = delegate RGB(Film!RGB film, Vec2i pos) { 
            Ray ray = generateRay(camera, film.size(), pos);
            return RGB([0.5f, 1.0f, 0.0f]);
        };
    }    
    
    @nogc void draw(T)(RGB function (T, Vec2i) @nogc  renderFn) {
        //pragma(msg, T.stringof);
        foreach(x; 0 .. size.x) {
            foreach(y; 0 .. size.y) {
                add(Vec2i([x, y]), renderFn(this, Vec2i ([x, y]) ) );
            }
        }
    }

    void run() {
        SDL_Init(SDL_INIT_VIDEO);
        SDL_Window* window = SDL_CreateWindow("SDL2 Displaying Image", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, _size.x, _size.y, cast(SDL_WindowFlags)(0));
        SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, cast(SDL_RendererFlags)(0));

        SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STATIC, _size.x(), _size.y() );

        ubyte[] buf = new ubyte[_size.x * _size.y * 4];

        bool quit = false;
        SDL_Event event;

        while (!quit) {
            clear();
            //draw!(drawCmd)();

            immutable auto render = function RGB(Window film, Vec2i pos) { 
                Ray ray = generateRay(film.camera, film.size(), pos);
                return RGB([0.5f, 1.0f, 0.0f]);
            };

            pragma(msg, typeof(render).stringof);
            draw!(Window)(render);

            foreach(x ; 0 .. _size.x()) {
                foreach(y ; 0 .. _size.y()) {
                    ubyte luminance = cast(ubyte)uniform(0, 255);
                    auto rgb = _pixels[((y * _size.x) + x)];

                    buf[((y * _size.x) + x) * 4 + 0] = 0xFF;
                    buf[((y * _size.x) + x) * 4 + 1] = cast(ubyte)clamp(cast(uint)(rgb.x * 255), 0, 255);
                    buf[((y * _size.x) + x) * 4 + 2] = cast(ubyte)clamp(cast(uint)(rgb.y * 255), 0, 255);
                    buf[((y * _size.x) + x) * 4 + 3] = cast(ubyte)clamp(cast(uint)(rgb.z * 255), 0, 255);
                }
            }
            SDL_UpdateTexture(texture, null, cast(const(void*))(buf.ptr), cast(int)(size.x() * uint.sizeof));

            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, null, null);
            SDL_RenderPresent(renderer);

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

    override void clear() {
        _pixels[].fill(RGB(0.0f));
    }

    override Vec2i size() {
        return _size;
    }

    override void add(Vec2i position, RGB contribution) {
        _pixels[position.x * size.y + position.y] = _pixels[position.x * size.y + position.y] + contribution;
    }
}