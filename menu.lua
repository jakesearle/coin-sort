function make_menu(callback)
    local menu = {

    }

    function menu:update()
        if btnp(❎) or btnp(🅾️) then
            callback()
        end
    end

    function menu:draw()
        cls(15)
        print_centered("\^w\^t" .. "coin sort", 0, 1, screenwidth, screenheight, 2)
        print_centered("\^w\^t" .. "coin sort", 0, 0, screenwidth, screenheight, 8)
        local bottom_str = "press ❎/🅾️ to start"
        local w, h = text_size(bottom_str)
        local x = (screenwidth - w) \ 2
        local y = screenheight - x - h
        print(bottom_str, x, y, 8)
    end

    return menu
end