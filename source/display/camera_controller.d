import vector;
import fast_math;
import constants;

import bindbc.sdl;

/// Camera controller, moving using arrow keys and mouse
/// Recycled from https://github.com/Hugobros3/bvh-viz/blob/master/src/controller.rs
struct CameraController {
    Vec3f position = Vec3f(0.0);
    Vec2f rotation = Vec2f([PI * 0.5, 0.0f]);

    Vec2i last_mouse = Vec2i(-1);

    bool update() {
        bool moved = false;
        Vec2i mouse_pos;
        auto state = SDL_GetMouseState(&mouse_pos.data[0], &mouse_pos.data[1]);
        auto is_button_down = state & SDL_BUTTON!(SDL_BUTTON_LEFT);

        if(is_button_down) {
            if(last_mouse.x != -1) {
                Vec2i delta = mouse_pos - last_mouse;
                float rotation_speed = 0.0125f * 0.25f;

                rotation.x += delta.x * rotation_speed;
                rotation.y -= delta.y * rotation_speed;
                moved = true;
            }

            last_mouse = mouse_pos;
        } else {
            last_mouse = Vec2i(-1);
        }

        auto key_states = SDL_GetKeyboardState(null);

        float move_speed = 0.125;

        if(key_states[SDL_SCANCODE_UP]) {
            position = position + get_view_dir() * move_speed;
            moved = true;
        } else if(key_states[SDL_SCANCODE_DOWN]) {
            position = position - get_view_dir() * move_speed;
            moved = true;
        } else if(key_states[SDL_SCANCODE_LEFT]) {
            float rot = rotation.x - PI * 0.5;
            position = position + Vec3f([ sin(rot), 0, cos(rot) ]) * move_speed;
            moved = true;
        }else if(key_states[SDL_SCANCODE_RIGHT]) {
            float rot = rotation.x + PI * 0.5;
            position = position + Vec3f([ sin(rot), 0, cos(rot) ]) * move_speed;
            moved = true;
        }

        return moved;
    }

    Vec3f get_view_dir() {
        return Vec3f([ sin(rotation.x) * cos (rotation.y), sin(rotation.y), cos(rotation.x) * cos(rotation.y) ]);
    }
}