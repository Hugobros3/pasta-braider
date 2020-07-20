import std.stdio;
import window;

import scene;

import cornell_balls;
import sphere;

import cornell_box;
import triangle;
import assimp;

void main(string[] args) {
    load_assimp();
    
	scope auto window = new Window!Triangle(make_cornell_box_scene());
    //scope auto window = new Window!Sphere(make_cornell_balls_scene());
    window.run();
}