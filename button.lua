function make_button(x, y, button_type)
    local color, text
    if button_type == LEVEL_CONFIG.BUTTON_TYPES.merge then
        color = 11
        text = "merge"
    else
        color = 12
        text = "deal"
    end
    button = {
        button_type = button_type,
        x = x,
        y = y,
        h = LEVEL_CONFIG.BUTTON.height,
        w = LEVEL_CONFIG.BUTTON.width,
        color = color,
        text = text,
        is_pressed = false
    }

    function button:draw()
        local shadow = get_shadow(self.color)
        local highlight = get_highlight(self.color)
        if self.is_pressed then
            local tmp = shadow
            shadow = highlight
            highlight = tmp
        end
        rectfill(self.x, self.y, self.x + self.w, self.y + self.h, color)
        -- Draw highlight
        line(self.x, self.y, self.x + self.w - 1, self.y, highlight)
        line(self.x, self.y, self.x, self.y + self.h - 1, highlight)
        -- Draw shadow
        line(self.x + 1, self.y + self.h, self.x + self.w, self.y + self.h, shadow)
        line(self.x + self.w, self.y + 1, self.x + self.w, self.y + self.h, shadow)
        -- Print text
        print_centered(self.text, self.x + 1, self.y + 1, self.w, self.h, shadow)
    end

    function button:get_pointer_xy()
        return self.x + (self.w \ 2), self.y - 5
    end

    function button:press()
        self.is_pressed = true
    end

    function button:release()
        self.is_pressed = false
    end

    return button
end

function get_highlight(color)
    if color == 11 or color == 12 then
        return 7
    end
end

function get_shadow(color)
    if color == 12 then return 1 end
    if color == 11 then return 3 end
end