-- game variables
local vars = {
    gw = 240, -- base resolution width
    gh = 208, -- base resolution height
    sx = 2, -- scale applied to base resolution x axis
    sy = 2, -- scale applied to base resolution y axis

    bounds = {
        right = nil,
        left = nil,
        top = nil,
        bottom = nil
    },

    colors = {
        default_color = {0.87, 0.87, 0.87},
        background_color = {0.06, 0.06, 0.06},
        ammo_color = {0.48, 0.78, 0.64},
        boost_color = {0.29, 0.76, 0.85},
        hp_color = {0.94, 0.40, 0.27},
        skill_point_color = {1, 0.77, 0.36}
    }
}

return vars