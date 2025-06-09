function make_tray(x, y, coin_values)
    local tray = {
        x = x,
        y = y,
        w = TRAY_CONFIG.width,
        h = TRAY_CONFIG.height,
        coins = {},
        -- Coins that are in the progress of being merged
        merging_coins = {},
        is_complete = false
    }

    function tray:init_coins(coin_values)
        local coins = {}
        for i, val in ipairs(coin_values) do
            local x, y = self:_xy_for_slot(i)
            local coin = make_coin(x, y, val)
            add(coins, coin)
        end
        self.coins = coins
        self:_calc_is_complete()
    end

    function tray:update()
        for coin in all(self.coins) do
            coin:update()
        end

        for coin in all(self.merging_coins) do
            if coin.tx == coin.x and coin.ty == coin.y then
                del(self.merging_coins, coin)
            else
                coin:update()
            end
        end
    end

    function tray:draw()
        -- Draw tray
        local tray_color = 6
        if self.is_complete then
            tray_color = 13
        end
        rectfill(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, tray_color)

        -- Draw slats
        for i = 1, TRAY_CONFIG.n_slots do
            local y = self.y + 2 + (i * 2)
            line(self.x + 1, y, self.x + self.w - 2, y, 5)
        end
        draw_all(self.merging_coins)
        draw_all(self.coins)
    end

    function tray:get_last_group()
        local group = {}
        local n = #self.coins
        if n == 0 then return group end
        local last = self.coins[n]
        local end_val = last.value
        add(group, last)

        for i = n - 1, 1, -1 do
            local coin = self.coins[i]
            if coin.value ~= end_val then break end
            add(group, coin, 1)
        end

        return group
    end

    function tray:get_pointer_xy()
        local group = self:get_last_group()
        local av_x = self.x + (self.w \ 2)
        local av_y
        if #group > 0 then
            av_y = average_y(group)
        else
            av_y = self.y
        end
        -- this accounts for the sprite placement
        return av_x - 2, av_y - 8
    end

    function tray:grab(grabbed_coins)
        remove_items(self.coins, grabbed_coins)
        self:_calc_is_complete()
    end

    function tray:empty_slots()
        return TRAY_CONFIG.n_slots - #self.coins
    end

    function tray:drop_into(dropped_coins, post_anim_state)
        local starting_i = #self.coins
        for i, c in ipairs(dropped_coins) do
            -- add the data
            local x, y = self:_xy_for_slot(starting_i + i)
            c:release(x, y, starting_i + i, post_anim_state)
            add(self.coins, c)
        end
        self:_calc_is_complete()
    end

    function tray:get_last_val()
        if #self.coins < 1 then
            return -1
        end
        return self.coins[#self.coins].value
    end

    function tray:reset_hover_anim()
        for i, c in ipairs(self.coins) do
            c.t = i * 4
        end
    end

    function tray:move_coins_up()
        local x, y = self:_xy_for_slot(1)
        local old_val = self.coins[1].value
        for c in all(self.coins) do
            add(self.merging_coins, c)
            del(self.coins, c)
            c:grab(x, y)
        end

        local new_coins = {}
        for i = 1, LEVEL_CONFIG.n_merge_new do
            add(new_coins, make_coin(x, y, old_val + 1))
        end
        self:drop_into(new_coins, COIN_STATE.idle)
    end

    function tray:_xy_for_slot(i)
        return self.x + 1, self.y - 3 + ((i - 1) * 2)
    end

    function tray:_calc_is_complete()
        self.is_complete = all_vals_eq(self.coins)
    end

    tray:init_coins(coin_values)
    return tray
end

function all_vals_eq(coins)
    if coins == nil or #coins < 10 then return false end

    local v = nil
    for c in all(coins) do
        if v == nil then
            v = c.value
        elseif c.value ~= v then
            return false
        end
    end
    return true
end