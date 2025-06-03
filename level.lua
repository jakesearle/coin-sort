function make_level(tray_values)
    local height = TRAY_CONFIG.height + 2
    local width = (#tray_values * (TRAY_CONFIG.width + 1)) + 1
    local x = (screenwidth - width) \ 2
    local y = (screenheight - height - LEVEL_CONFIG.button_area_height) \ 2

    local has_hovered = false
    local trays = {}
    local pointer
    for i, tray in ipairs(tray_values) do
        local is_hovered = false
        if has_hovered == false then
            is_hovered = true
            has_hovered = true
        end
        local tray_obj = make_tray(
            x + ((i - 1) * (TRAY_CONFIG.width + 1)) + 1,
            y + 1,
            tray
        )
        if is_hovered then
            -- set chip's is_hovered
            for i, c in ipairs(tray_obj:get_last_group()) do
                c:start_hover(i)
            end
            -- make pointer
            local x, y = tray_obj:get_pointer_xy()
            pointer = make_pointer(i, x, y)
        end
        add(trays, tray_obj)
    end

    local b_types = { LEVEL_CONFIG.BUTTON_TYPES.deal, LEVEL_CONFIG.BUTTON_TYPES.merge }
    local button_zone_x, button_zone_y = 0, screenheight - LEVEL_CONFIG.button_area_height
    local button_margin = 1
    all_buttons_width = (#b_types * (LEVEL_CONFIG.BUTTON.width + LEVEL_CONFIG.BUTTON.margin)) - LEVEL_CONFIG.BUTTON.margin
    all_buttons_height = LEVEL_CONFIG.BUTTON.height
    all_buttons_x = (screenwidth - all_buttons_width) \ 2
    all_buttons_y = ((LEVEL_CONFIG.button_area_height - all_buttons_height) \ 2) + button_zone_y

    local buttons = {}
    for i, t in ipairs(b_types) do
        local b_x = all_buttons_x + ((i - 1) * (LEVEL_CONFIG.BUTTON.width + LEVEL_CONFIG.BUTTON.margin))
        local b_y = all_buttons_y
        local b = make_button(b_x, b_y, t)
        add(buttons, b)
    end

    local level = {
        trays = trays,
        pointer = pointer,
        buttons = buttons,
        height = height,
        width = width,
        x = x,
        y = y,
        state = LEVEL_STATE.hovering
    }

    function level:update()
        if self.state == LEVEL_STATE.hovering then
            if btnp(⬇️) then
                self:move_down()
            elseif btnp(⬆️) then
                self:move_up()
            elseif btnp(➡️) then
                self:move_pointer(1)
            elseif btnp(⬅️) then
                self:move_pointer(-1)
            elseif btnp(❎) then
                self:x_down()
            elseif btnr(❎) then
                self:x_up()
            end
        elseif self.state == LEVEL_STATE.grabbing then
            if btnr(❎) then
                self:release_chips()
            elseif btnp(➡️) then
                self:move_pointer(1)
            elseif btnp(⬅️) then
                self:move_pointer(-1)
            end
        end

        if btnp(🅾️) then
            for t in all(self.trays) do
                for c in all(t.coins) do
                    c.value += #self.trays
                end
            end
        end

        self:update_children()
    end

    function level:draw()
        draw_all(self.trays)
        draw_all(self.buttons)

        -- Draw releasing coins on top
        for tray in all(self.trays) do
            for c in all(tray.coins) do
                if c.state == COIN_STATE.releasing then
                    c:draw()
                end
            end
        end

        self.pointer:draw()
    end

    function level:update_children()
        -- update children
        for tray in all(self.trays) do
            tray:update()
        end
        self.pointer:update()
    end

    function level:move_pointer(dir)
        if self.pointer:is_hovering_tray() then
            self:move_pointer_tray(dir)
        else
            self:move_pointer_button(dir)
        end
    end

    function level:move_pointer_tray(dir)
        local old_i = self.pointer.tray_i
        local tray_count = #self.trays
        local new_i = ((old_i - 1 + dir) % tray_count) + 1

        if self.state == LEVEL_STATE.hovering then
            for c in all(self.trays[old_i]:get_last_group()) do
                c:stop_hover()
            end

            for i, c in ipairs(self.trays[new_i]:get_last_group()) do
                c:start_hover(i)
            end
        end

        local new_x, new_y = self.trays[new_i]:get_pointer_xy()
        self.pointer:move_to_tray(new_i, new_x, new_y)
    end

    function level:move_pointer_button(dir)
        local new_i = ((self.pointer.button_i - 1 + dir) % #self.buttons) + 1

        local new_x, new_y = self.buttons[new_i]:get_pointer_xy()
        self:pointed_button():release()
        self.pointer:move_to_button(new_i, new_x, new_y)
    end

    function level:move_down()
        if self.pointer:is_hovering_tray() then
            self:pointer_tray_to_button()
        else
            self:pointer_button_to_tray()
        end
    end

    function level:move_up()
        if self.pointer:is_hovering_tray() then
            self:pointer_tray_to_button()
        else
            self:pointer_button_to_tray()
        end
    end

    function level:pointer_tray_to_button()
        local i = self.pointer.prev_button_i

        if not i then
            local nearest = nearest_item(self.buttons, self.pointer.x, self.pointer.y)
            i = index_of(self.buttons, nearest)
        end

        local nx, ny = self.buttons[i]:get_pointer_xy()
        for c in all(self:pointed_tray():get_last_group()) do
            c:stop_hover()
        end
        self.pointer:move_to_button(i, nx, ny)
    end

    function level:pointer_button_to_tray()
        local i = self.pointer.prev_tray_i

        if not i then
            local nearest = nearest_item(self.trays, self.pointer.x, self.pointer.y)
            i = index_of(self.trays, nearest)
        end

        local nx, ny = self.trays[i]:get_pointer_xy()
        self:pointed_button():release()
        self.pointer:move_to_tray(i, nx, ny)
        self:pointed_tray():reset_hover_anim()
        self:recalc_is_hover()
    end

    function level:x_down()
        if self.pointer:is_hovering_button() then
            self:button_down()
        elseif self.pointer:is_hovering_tray() then
            self:grab_chips()
        end
    end

    function level:x_up()
        if self.pointer:is_hovering_button() then
            self:button_up()
        end
    end

    function level:grab_chips()
        if #self:pointed_tray().coins < 1 then return end
        self.state = LEVEL_STATE.grabbing
        local hovering_coins = self:pointed_tray():get_last_group()

        self.pointer:grab(hovering_coins)
        self:pointed_tray():grab(hovering_coins)
    end

    function level:button_down()
        self:pointed_button():press()
    end

    function level:button_up()
        self:pointed_button():release()
        if self:pointed_button().button_type == LEVEL_CONFIG.BUTTON_TYPES.merge then
            self:merge()
        elseif self:pointed_button().button_type == LEVEL_CONFIG.BUTTON_TYPES.deal then
            self:deal()
        end
    end

    function level:release_chips()
        local pointer = self.pointer
        local tray = self:pointed_tray()
        local held_val = pointer:held_val()
        local last_val = tray:get_last_val()
        local n_held = #pointer.held_coins
        local n_empty = tray:empty_slots()
        local is_empty = n_empty == TRAY_CONFIG.n_slots

        local released = pointer:release()

        self.state = LEVEL_STATE.hovering

        if n_empty >= n_held and (held_val == last_val or is_empty) then
            -- Full match or drop into empty column
            tray:drop_into(released, COIN_STATE.hovering)
        elseif held_val == last_val then
            -- Partial match
            local n_extra = n_held - n_empty
            local wrong, right = split_list(released, n_extra)
            tray:drop_into(right, COIN_STATE.hovering)
            self.trays[pointer.coins_from]:drop_into(wrong, COIN_STATE.idle)
        elseif pointer.tray_i ~= pointer.coins_from then
            -- Invalid column
            -- TODO: Sound effect
            self.trays[pointer.coins_from]:drop_into(released, COIN_STATE.idle)
        else
            -- Return to original column
            self.trays[pointer.coins_from]:drop_into(released, COIN_STATE.hovering)
        end

        tray:reset_hover_anim()
        self:recalc_is_hover()
    end

    function level:pointed_tray()
        return self.trays[self.pointer.tray_i]
    end

    function level:pointed_button()
        return self.buttons[self.pointer.button_i]
    end

    function level:recalc_is_hover()
        -- Set all to none
        for t in all(self.trays) do
            for c in all(t.coins) do
                if c.state == COIN_STATE.hovering then
                    c.state = COIN_STATE.idle
                end
            end
        end
        -- Set hovering
        for c in all(self:pointed_tray():get_last_group()) do
            if c.state == COIN_STATE.idle then
                c.state = COIN_STATE.hovering
            end
        end
    end

    function level:merge()
        for t in all(self.trays) do
            if t.is_complete then
                t:move_coins_up()
            end
        end
    end

    function level:deal()
        local dealable = self:dealable_coins()
        local smallest_coin = self:smallest_key(dealable)
        local n_smallest = dealable[smallest_coin]
        local max_smallest_to_deal = nil
        local start_x, start_y = self:pointed_button():get_pointer_xy()
        local n_coins_generated = 0

        if #dealable >= #self.trays and (n_smallest % TRAY_CONFIG.n_slots) == 0 then
            -- If we've got too many chip types, AND
            -- we have the right amount, just don't generate any more
            dealable[smallest_coin] = nil
        elseif #dealable >= #self.trays then
            -- If we've got too many chip types, AND
            -- we don't have the right amount, only generate enough
            max_smallest_to_deal = TRAY_CONFIG.n_slots - (n_smallest % TRAY_CONFIG.n_slots)
        end

        for t in all(self.trays) do
            local to_deal = random_item(LEVEL_CONFIG.n_to_deal)
            local empty_slots = t:empty_slots()
            local actual_to_deal = min(to_deal, empty_slots)
            local val = random_key(dealable)
            if smallest_coin == val and max_smallest_to_deal ~= nil and max_smallest_to_deal >= 0 then
                if actual_to_deal >= max_smallest_to_deal then
                    actual_to_deal = max_smallest_to_deal
                    max_smallest_to_deal = 0
                else
                    max_smallest_to_deal -= actual_to_deal
                end
            end
            if actual_to_deal ~= 0 then
                -- we want to actually deal coins
                -- normal generate
                local new_coins = {}
                for i = 1, actual_to_deal do
                    add(new_coins, make_coin(start_x, start_y, val))
                    n_coins_generated += 1
                end
                t:drop_into(new_coins, COIN_STATE.idle)
            end
        end

        if n_coins_generated == 0 then
            self:deal()
        end
    end

    function level:dealable_coins()
        local ccs = self:current_coins()
        local n_types = n_keys(ccs)
        local min_types = #self.trays - 1
        if n_types >= min_types then return ccs end

        if n_types == 0 then
            local ret = {}
            for i = 1, min_types do
                ret[i] = 1
            end
            return ret
        end

        local top_val = self:largest_key(ccs)
        local bottom_val = max(1, top_val - min_types + 1)
        for i = top_val, bottom_val, -1 do
            if ccs[i] == nil then
                ccs[i] = 1
            end
        end
        return ccs
    end

    function level:current_coins()
        local seen = {}
        for tray in all(self.trays) do
            for coin in all(tray.coins) do
                local v = coin.value
                if not seen[v] then
                    seen[v] = 1
                else
                    seen[v] += 1
                end
            end
        end
        return seen
    end

    function level:smallest_key(coins)
        local min = nil
        for k, _ in pairs(coins) do
            if min == nil or k < min then
                min = k
            end
        end
        return min
    end

    function level:largest_key(coins)
        local min = nil
        for k, _ in pairs(coins) do
            if min == nil or k > min then
                min = k
            end
        end
        return min
    end

    return level
end