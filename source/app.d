import std.stdio;
import window;

import scene;

import balls;
import cornell_balls;
import sphere;

import triangle;
import assimp;

void main(string[] args) {
    load_assimp();
    auto scene = args.length >= 2 ? args[1] : "scenes/cornell.glb";
    scope auto window = new Window!Triangle(load_tri_scene(scene));
    //scope auto window = new Window!Sphere(make_balls_scene());
    window.run();
}
