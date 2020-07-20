import std.stdio;
import window;

import cornell_balls;
import scene;
import sphere;

import assimp;

void main(string[] args) {
    load_assimp();
    load("scenes/cornell.glb");
    scope auto window = new Window!Sphere(make_cornell_balls_scene());
    window.run();
}