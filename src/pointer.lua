function make_pointer(i, j, x, y)
    pointer = {
        tray_i = i, -- which tray I'm pointing to
        tray_j = j,
        button_i = nil, -- which button I'm pointing to
        x = x,
        y = y,
        tx = x,
        ty = y,
        vx = 0, -- velocity
        vy = 0,
        sprite = 16,
        held_coins = {},
        coins_from = nil
    }

    function pointer:update()
        if not (approx_eq(self.x, self.tx) and approx_eq(self.y, self.ty)) then
            self:spring_animation()
        end
        for c in all(self.held_coins) do
            c:snap_xy(self:grab_point())
            c:update()
        end
    end

    function pointer:spring_animation()
        -- spring animation
        local stiffness = 0.2
        local damping = 0.6

        local dx = self.tx - self.x
        local dy = self.ty - self.y

        self.vx = self.vx * damping + dx * stiffness
        self.vy = self.vy * damping + dy * stiffness

        self.x += self.vx
        self.y += self.vy
    end

    function pointer:draw()
        draw_all(self.held_coins)
        spr(self.sprite, self.x, self.y)
    end

    function pointer:move_to_tray(i, j, nx, ny)
        self.tray_i = i
        self.tray_j = j
        self.button_i = nil
        self.tx = nx
        self.ty = ny
    end

    function pointer:move_to_button(i, nx, ny)
        self.tray_i = nil
        self.tray_j = nil
        self.button_i = i
        self.tx = nx
        self.ty = ny
    end

    function pointer:grab(coins)
        self.coins_from = { self.tray_i, self.tray_j }
        self.held_coins = coins
        local x, y = self:grab_point()
        for c in all(self.held_coins) do
            c:grab(x, y)
        end
        self.sprite = 18
    end

    function pointer:grab_point()
        return self.x, self.y + 4
    end

    function pointer:release()
        self.sprite = 16
        local ret = self.held_coins
        self.held_coins = {}
        return ret
    end

    function pointer:held_val()
        if #self.held_coins < 1 then
            return nil
        end
        return self.held_coins[1].value
    end

    function pointer:assert_valid()
        assert(self.tray_i ~= nil or self.button_i ~= nil, "Both pointer i variables are unset")
        assert(self.tray_i == nil or self.button_i == nil, "Both pointer i variables are set")
    end

    function pointer:is_hovering_tray()
        self:assert_valid()
        return self.tray_i ~= nil and self.button_i == nil
    end

    function pointer:is_hovering_button()
        self:assert_valid()
        return self.tray_i == nil and self.button_i ~= nil
    end

    return pointer
end