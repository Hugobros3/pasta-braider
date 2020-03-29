import std.algorithm.mutation;

import film;
import color;
import vector;

import bindbc.sdl;

class Windows : Film!(RGB) {
    private Vec2i _size = [512, 512];
    private RGB[] _pixels;

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