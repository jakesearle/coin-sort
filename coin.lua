function make_coin(x, y, value)
    local coin = {
        value = value,
        x = x,
        y = y,
        state = COIN_STATE.idle,
        sprite = value,
        -- For hover animation
        t = 0,
        base_y = y,
        -- For moving animation
        tx = x,
        ty = y,
        vx = 0, -- velocity
        vy = 0
    }

    function coin:update()
        self.t += 1

        if self.state == COIN_STATE.hovering then
            -- This is a bugfix for "hovering" getting applied too soon
            if self.x ~= self.tx then
                self.x = self.tx
            end
            local bob_y = -3
            if self.t > 35 then
                bob_y += -(min(0, sin(self.t / 70)) * 4)
            end
            self.y = self.base_y + bob_y
        elseif self.state == COIN_STATE.grabbing then
            -- move toward target
            local is_finished = self:update_moving()
            if is_finished then
                self.state = self.post_anim_state
            end
        elseif self.state == COIN_STATE.releasing then
            local is_finished = self:update_moving()
            if is_finished then
                self.state = self.post_anim_state
            end
        end
    end

    function coin:update_moving()
        -- spring animation
        local stiffness = 0.9
        local damping = 0.1
        local velocity_threshold = 0.1
        -- how slow is "slow enough"

        local dx = self.tx - self.x
        local dy = self.ty - self.y

        self.vx = self.vx * damping + dx * stiffness
        self.vy = self.vy * damping + dy * stiffness

        self.x += self.vx
        self.y += self.vy

        local speed = sqrt(self.vx ^ 2 + self.vy ^ 2)

        if speed < velocity_threshold then
            self.x = self.tx
            self.y = self.ty
            self.vx = 0
            self.vy = 0
            return true
        end

        return false
    end

    function coin:draw()
        if self.state == COIN_STATE.invisible then return end
        spr(self.sprite, self.x, self.y)
    end

    function coin:start_hover(i)
        self.state = COIN_STATE.hovering
        self.t = i * 4
    end

    function coin:stop_hover()
        self.state = COIN_STATE.idle
        self.x = self.tx
        self.y = self.base_y
    end

    function coin:grab(nx, ny)
        self.state = COIN_STATE.grabbing
        self.post_anim_state = COIN_STATE.idle
        self.tx = nx
        self.ty = ny
    end

    function coin:release(nx, ny, i, post_anim_state)
        self.state = COIN_STATE.releasing
        self.post_anim_state = post_anim_state
        self.tx = nx
        self.ty = ny
        if post_anim_state == COIN_STATE.hovering then
            self.ty -= COIN_CONFIG.hover_offset
        end
        self.base_y = ny
        self.t = i * 4
    end

    function coin:snap_xy(nx, ny)
        self.x = nx
        self.tx = nx
        self.y = ny
        self.ty = ny
    end

    return coin
end