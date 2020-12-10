import std.stdio;
import window;

import scene;

import cornell_balls;
import sphere;

import triangle;
import assimp;

void main(string[] args) {
    load_assimp();
    //scope auto window = new Window!Triangle(load_tri_scene("scenes/cornell.glb"));
    scope auto window = new Window!Sphere(make_cornell_balls_scene());
    window.run();
}
