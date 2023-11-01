return {
    -- controls
    {
    left = "a",
    right = "d",
    jump = "w",
    menu = "tab",
    },

    -- alt_controls
    {
    left = "left",
    right = "right",
    jump = "up",
    },

    -- player
    {
    rgb = {0.5, 0.1, 0.3},
    speed = 210,
    float_coefficient = 0.3,
    drag_coefficient = 0.8,
    jump_strength = 500,
    vx = 0,
    vy = 0,
    is_colliding_top = false,
    is_colliding_bot = false,
    is_colliding_left = false,
    is_colliding_right = false
    },

    -- gravity
    30,
    
    -- terminal_velocity
    500
}
