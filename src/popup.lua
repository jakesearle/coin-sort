function make_popup(title, main_menu_callback, restart_callback)
    local b_types = { LEVEL_CONFIG.BUTTON_TYPES.main_menu, LEVEL_CONFIG.BUTTON_TYPES.restart }
    local button_margin = LEVEL_CONFIG.BUTTON.margin

    local popup = {
        title = title,
        x_message = x_message,
        x_callback = x_callback,
        o_message = o_message,
        o_callback = o_callback,
        t_w = 96,
        t_h = 64,
        w = 1,
        h = 1,
        r_squircle = 8,
        t = 0,
        vw = 0,
        vh = 0
    }

    function popup:init()
        self.buttons = {}
        for i, t in ipairs(b_types) do
            local button = make_button(nil, nil, t)
            add(self.buttons, button)
        end
    end

    function popup:update()
        self.t += 1
        -- Popup animation
        if self.w ~= self.t_w or self.h ~= self.t_h then
            local finished = self:_update_scaling()
            self:_update_positions()
            if finished then
                button_i = 2
                local x, y = self.buttons[button_i]:get_pointer_xy()
                self.pointer = make_pointer(nil, nil, x, y)
                self.pointer.button_i = button_i
            end
        end

        if self.pointer then
            if btnp(➡️) then
                self:_move_pointer(1)
            elseif btnp(⬅️) then
                self:_move_pointer(-1)
            elseif btnp(❎) then
                self:_button_down()
            elseif btnr(❎) then
                self:_button_up()
            end
            self.pointer:update()
        end
    end

    function popup:draw()
        -- Shadow
        squircle_fill(self.x + 4, self.y + 4, self.w, self.h, self.r_squircle, 0)
        -- Border
        squircle_fill(self.x, self.y, self.w, self.h, self.r_squircle, 2)
        -- Body
        squircle_fill(self.x + 1, self.y + 1, self.w - 2, self.h - 2, self.r_squircle, 15)
        self:_draw_header()
        self:_draw_buttons()
        if self.pointer then
            self.pointer:draw()
        end
    end

    function popup:_button_down()
        self:_get_pointed_button():press()
    end

    function popup:_button_up()
        self:_get_pointed_button():release()
        local type = self:_get_pointed_button().button_type
        if type == LEVEL_CONFIG.BUTTON_TYPES.main_menu then
            main_menu_callback()
        elseif type == LEVEL_CONFIG.BUTTON_TYPES.restart then
            restart_callback()
        end
    end

    function popup:_draw_buttons()
        local total_button_w = #self.buttons * self.buttons[1].w
        if self.button_container.w >= total_button_w then
            draw_all(self.buttons)
        end
    end

    function popup:_draw_header()
        -- Header
        squircle_fill(self.header.x, self.header.y, self.header.w, self.header.h, self.r_squircle, 2)
        local t_text = "\^w\^t" .. self.title
        local text_w, _ = text_size(t_text)
        if self.header.w >= text_w then
            print_centered(t_text, self.header.x, self.header.y + 1, self.header.w, self.header.h, 8)
        end
    end

    function popup:_get_pointed_button()
        return self.buttons[self.pointer.button_i]
    end

    function popup:_move_pointer(dir)
        local new_i = ((self.pointer.button_i - 1 + dir) % #self.buttons) + 1
        local new_x, new_y = self.buttons[new_i]:get_pointer_xy()
        self:_get_pointed_button():release()
        self.pointer:move_to_button(new_i, new_x, new_y)
    end

    function popup:_update_positions()
        self.x = (screenwidth - self.w) \ 2
        self.y = (screenheight - self.h) \ 2

        if not self.header then self.header = {} end
        self.header.x = self.x + 2
        self.header.y = self.y + 2
        self.header.w = self.w - 4
        self.header.h = self.r_squircle * 2

        if not self.button_container then self.button_container = {} end
        self.button_container.x = self.header.x
        self.button_container.y = self.header.y + self.header.h
        self.button_container.w = self.header.w
        self.button_container.h = self.h - self.header.h - self.r_squircle

        local total_button_w = #self.buttons * self.buttons[1].w
        local margin_w = (self.button_container.w - total_button_w) \ (#self.buttons + 1)
        local curr_x = self.button_container.x + margin_w
        for i, b in ipairs(self.buttons) do
            b.x = curr_x
            b.y = (self.button_container.h - self.buttons[1].h) \ 2 + self.button_container.y
            curr_x += margin_w + b.w
        end
    end

    function popup:_update_scaling()
        -- spring animation
        local stiffness = 0.5
        local damping = 0.55
        local velocity_threshold = 0.05
        -- how slow is "slow enough"

        local dw = self.t_w - self.w
        local dh = self.t_h - self.h

        self.vw = self.vw * damping + dw * stiffness
        self.vh = self.vh * damping + dh * stiffness

        self.w += self.vw
        self.h += self.vh

        local speed = sqrt(self.vw ^ 2 + self.vh ^ 2)

        if speed < velocity_threshold then
            self.w = self.t_w
            self.h = self.t_h
            self.vw = 0
            self.vh = 0
            return true
        end

        return false
    end

    popup:init()
    return popup
end