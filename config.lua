-- global vars
screenwidth = 127
screenheight = 127

level1 = {
    {},
    {},
    {},
    {},
    {}
}

LEVEL_STATE = {
    hovering = 1,
    grabbing = 2
}

LEVEL_CONFIG = {
    button_area_height = 32,
    n_to_deal = { 4, 3, 2, 0 },
    n_merge_new = 2,
    BUTTON_TYPES = {
        deal = 1,
        merge = 2
    },
    BUTTON = {
        height = 10,
        width = 30,
        margin = 5
    }
}

TRAY_CONFIG = {
    width = 10,
    height = 25,
    n_slots = 10
}

COIN_CONFIG = {
    hover_offset = 3
}

COIN_STATE = {
    idle = 1,
    hovering = 2,
    grabbing = 3,
    releasing = 4
}

TIME = {
    second = 30
}