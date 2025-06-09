function make_level(tray_values)
    local level = {
        pointer = pointer,
        buttons = buttons,
        state = LEVEL_STATE.hovering,
        high_score = load_big_number(),
        score = make_bigint(0)
    }

    function level:init()
        local tray_grid = {}
        local one_row_vals = { 1, 2, 3, 4, 5, 7 }
        local two_row_vals = { 6, 8, 10 }
        if contains(one_row_vals, #tray_values) then
            tray_grid = { tray_values }
        elseif contains(two_row_vals, #tray_values) then
            tray_grid = split_into_parts(tray_values, 2)
        else
            tray_grid = split_into_parts(tray_values, 3)
        end

        -- i: row, j:col
        local n_rows = #tray_grid
        local n_cols = #tray_grid[1]

        -- Size & Shape
        self.h = (TRAY_CONFIG.height + 1) * n_rows
        self.w = (TRAY_CONFIG.width + 1) * n_cols
        self.x = (screenwidth - self.w) \ 2
        self.y = ((screenheight - self.h - LEVEL_CONFIG.button_area_height - LEVEL_CONFIG.score_area_height) \ 2) + LEVEL_CONFIG.score_area_height

        self.tray_grid = {}
        -- local center_i, center_j = (n_rows \ 2) + 1, (n_cols \ 2) + 1
        local center_i, center_j = 1, 1
        for i, row_vals in ipairs(tray_grid) do
            local row = {}
            local row_w = (TRAY_CONFIG.width + 1) * #row_vals
            local row_x = ((self.w - row_w) \ 2) + self.x
            for j, tray_vals in ipairs(row_vals) do
                local tray_x = row_x + ((j - 1) * (TRAY_CONFIG.width + 1))
                local tray_y = self.y + ((i - 1) * (TRAY_CONFIG.height + 1))
                local tray_obj = make_tray(tray_x, tray_y, tray_vals)
                add(row, tray_obj)

                if i == center_i and j == center_j then
                    local px, py = tray_obj:get_pointer_xy()
                    self.pointer = make_pointer(i, j, px, py)
                end
            end
            add(self.tray_grid, row)
        end

        local b_types = { LEVEL_CONFIG.BUTTON_TYPES.deal, LEVEL_CONFIG.BUTTON_TYPES.merge }
        local button_zone_x, button_zone_y = 0, screenheight - LEVEL_CONFIG.button_area_height
        local button_margin = 1
        all_buttons_width = (#b_types * (LEVEL_CONFIG.BUTTON.width + LEVEL_CONFIG.BUTTON.margin))
                - LEVEL_CONFIG.BUTTON.margin
        all_buttons_height = LEVEL_CONFIG.BUTTON.height
        all_buttons_x = (screenwidth - all_buttons_width) \ 2
        all_buttons_y = ((LEVEL_CONFIG.button_area_height - all_buttons_height) \ 2) + button_zone_y

        self.buttons = {}
        for i, t in ipairs(b_types) do
            local b_x = all_buttons_x + ((i - 1) * (LEVEL_CONFIG.BUTTON.width + LEVEL_CONFIG.BUTTON.margin))
            local b_y = all_buttons_y
            local b = make_button(b_x, b_y, t)
            add(self.buttons, b)
        end
    end

    function level:update()
        if self.state == LEVEL_STATE.hovering then
            local dx, dy = 0, 0
            if btnp(⬅️) then dx -= 1 end
            if btnp(➡️) then dx += 1 end
            if btnp(⬆️) then dy -= 1 end
            if btnp(⬇️) then dy += 1 end

            if dx ~= 0 or dy ~= 0 then
                self:move_pointer(dx, dy)
            end

            if btnp(❎) then
                self:x_down()
            elseif btnr(❎) then
                self:x_up()
            elseif btnp(🅾️) then
                self:merge_button_down()
            elseif btnr(🅾️) then
                self:merge_button_up()
            end
        elseif self.state == LEVEL_STATE.grabbing then
            local dx, dy = 0, 0
            if btnp(⬅️) then dx -= 1 end
            if btnp(➡️) then dx += 1 end
            if btnp(⬆️) then dy -= 1 end
            if btnp(⬇️) then dy += 1 end

            if dx ~= 0 or dy ~= 0 then
                self:move_pointer(dx, dy)
            end

            if btnr(❎) then
                self:release_chips()
            end
        end

        self:update_children()
    end

    function level:draw()
        local go = self:is_gameover()
        for row in all(self.tray_grid) do
            draw_all(row)
        end

        if not go then
            draw_all(self.buttons)
        end

        self:_draw_score()

        -- Draw releasing coins on top
        for row in all(self.tray_grid) do
            for tray in all(row) do
                for c in all(tray.coins) do
                    if c.state == COIN_STATE.releasing then
                        c:draw()
                    end
                end
            end
        end
        if not go then
            self.pointer:draw()
        end
    end

    function level:_draw_score()
        local score_label = "score"
        local w, h = text_size(score_label)
        local x = screenwidth - w + 1
        local y = 1
        print(score_label, x, y, 14)

        local score_val = format_bigint(self.score)
        y = y + h
        w, _ = text_size(score_val)
        x = screenwidth - w + 1
        print(score_val, x, y)

        print("best", 1, 1)
        print(format_bigint(self.high_score))
    end

    function level:update_children()
        -- update children
        for row in all(self.tray_grid) do
            for tray in all(row) do
                tray:update()
            end
        end
        self.pointer:update()
    end

    function level:move_pointer(dx, dy)
        local current_item = self:pointed_button() or self:pointed_tray()
        local all_items = flatten(self.tray_grid)
        if self.state ~= LEVEL_STATE.grabbing then
            extend(all_items, self.buttons)
        end
        local best_item = self:find_item_in_direction(current_item, all_items, dx, dy)

        for i, row in ipairs(self.tray_grid) do
            for j, tray in ipairs(row) do
                if tray == best_item then
                    local nx, ny = tray:get_pointer_xy()
                    self.pointer:move_to_tray(i, j, nx, ny)
                end
            end
        end

        for i, button in ipairs(self.buttons) do
            if best_item == button then
                local nx, ny = button:get_pointer_xy()
                self.pointer:move_to_button(i, nx, ny)
            end
        end

        self:recalc_active_buttons()
        self:recalc_pressed_buttons()
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

    function level:merge_button_down()
        for b in all(self.buttons) do
            if b.button_type == LEVEL_CONFIG.BUTTON_TYPES.merge then
                b:press()
            end
        end
    end

    function level:merge_button_up()
        for b in all(self.buttons) do
            if b.button_type == LEVEL_CONFIG.BUTTON_TYPES.merge then
                b:release()
            end
        end
        self:merge()
    end

    function level:button_down()
        self:pointed_button():press()
    end

    function level:button_up()
        self:pointed_button():release()
        if not self:pointed_button().is_enabled then
            return
        end
        if self:pointed_button().button_type == LEVEL_CONFIG.BUTTON_TYPES.merge then
            self:merge()
        elseif self:pointed_button().button_type == LEVEL_CONFIG.BUTTON_TYPES.deal then
            self:deal()
        end
    end

    function level:release_chips()
        local pointer = self.pointer
        local tray = self:pointed_tray()
        local from_i, from_j = unpack(self.pointer.coins_from)
        local tray_from = self.tray_grid[from_i][from_j]
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
            tray_from:drop_into(wrong, COIN_STATE.idle)
        elseif pointer.tray_i ~= pointer.coins_from then
            -- Invalid column
            -- TODO: Sound effect
            tray_from:drop_into(released, COIN_STATE.idle)
        else
            -- Return to original column
            tray_from:drop_into(released, COIN_STATE.hovering)
        end

        tray:reset_hover_anim()
        self:recalc_is_hover()
        self:recalc_active_buttons()
    end

    function level:pointed_tray()
        if self.tray_grid == nil
                or self.pointer.tray_i == nil
                or self.pointer.tray_i == nil
                or self.tray_grid[self.pointer.tray_i] == nil then
            return nil
        end
        return self.tray_grid[self.pointer.tray_i][self.pointer.tray_j]
    end

    function level:pointed_button()
        if not self.buttons then return nil end
        return self.buttons[self.pointer.button_i]
    end

    function level:recalc_is_hover()
        -- Set all to none
        for r in all(self.tray_grid) do
            for t in all(r) do
                for c in all(t.coins) do
                    if c.state == COIN_STATE.hovering then
                        c:stop_hover()
                    end
                end
            end
        end
        -- Set hovering
        if self:pointed_tray() ~= nil then
            for i, c in ipairs(self:pointed_tray():get_last_group()) do
                if c.state == COIN_STATE.idle then
                    c:start_hover(i)
                end
            end
        end
    end

    function level:merge()
        for t in all(flatten(self.tray_grid)) do
            if t.is_complete then
                local big_i = make_bigint(t:get_last_val())
                local sub_total = mult_bigint(big_i, big_i) .. "00"
                self.score = add_bigint(self.score, sub_total)

                t:move_coins_up()
            end
        end
        if gt_bigint(self.score, self.high_score) then
            self.high_score = self.score
            load_big_number(self.high_score)
            save_big_number(self.high_score)
        end
        self:recalc_active_buttons()
    end

    function level:deal()
        local dealable = self:dealable_coins()
        local smallest_coin = self:smallest_key(dealable)
        local n_smallest = dealable[smallest_coin]
        local max_smallest_to_deal = nil
        local start_x, start_y = self:pointed_button():get_pointer_xy()
        local n_coins_generated = 0

        if #dealable >= #self.tray_grid and (n_smallest % TRAY_CONFIG.n_slots) == 0 then
            -- If we've got too many chip types, AND
            -- we have the right amount, just don't generate any more
            dealable[smallest_coin] = nil
        elseif #dealable >= #self.tray_grid then
            -- If we've got too many chip types, AND
            -- we don't have the right amount, only generate enough
            max_smallest_to_deal = TRAY_CONFIG.n_slots - (n_smallest % TRAY_CONFIG.n_slots)
        end

        for t in all(flatten(self.tray_grid)) do
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
        self:recalc_active_buttons()
    end

    function level:dealable_coins()
        local ccs = self:current_coins()
        local n_types = n_keys(ccs)
        local min_types = #flatten(self.tray_grid) - 1
        -- if n_types >= min_types then return ccs end

        if n_types == 0 then
            local ret = {}
            ret[1] = 0
            return ret
        end

        -- Fill in missing values
        -- If we've got a bunch of trays, but have missing values
        -- ex: {10, 9, 7, 6}
        -- This will add back in 8 (given that there's enough trays to do it)
        -- If they player hasn't gotten rid of smaller values, that's a skill issue
        local top_val = self:largest_key(ccs)
        local bottom_val = max(1, top_val - min_types + 1)
        for i = top_val, bottom_val, -1 do
            if ccs[i] == nil then
                ccs[i] = 1
            end
        end

        -- Don't coins of the highest value type
        -- Gotta work for that
        if n_keys(ccs) > 1 then
            ccs[top_val] = nil
        end
        return ccs
    end

    function level:current_coins()
        local seen = {}
        for row in all(self.tray_grid) do
            for tray in all(row) do
                for coin in all(tray.coins) do
                    local v = coin.value
                    if not seen[v] then
                        seen[v] = 1
                    else
                        seen[v] += 1
                    end
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

    function level:recalc_active_buttons()
        local can_merge = false
        local can_deal = false
        for t in all(flatten(self.tray_grid)) do
            if t.is_complete then
                can_merge = true
            end
            if t:empty_slots() > 0 then
                can_deal = true
            end

            if can_deal and can_merge then break end
        end

        for b in all(self.buttons) do
            if b.button_type == LEVEL_CONFIG.BUTTON_TYPES.merge then
                b.is_enabled = can_merge
            elseif b.button_type == LEVEL_CONFIG.BUTTON_TYPES.deal then
                b.is_enabled = can_deal
            end
        end
    end

    function level:recalc_pressed_buttons()
        for b in all(self.buttons) do
            b:release()
        end
        if self:pointed_button() and btn(❎) then
            self:pointed_button():press()
        end
    end

    function level:is_gameover()
        for row in all(self.tray_grid) do
            for t in all(row) do
                if t.is_complete then
                    return false
                end
                if t:empty_slots() > 0 then
                    return false
                end
            end
        end

        return true
    end

    function level:find_item_in_direction(curr_item, items, dx, dy)
        local cx, cy = curr_item.x + curr_item.w / 2, curr_item.y + curr_item.h / 2
        local target = self:search(curr_item, cx, cy, items, dx, dy)
        if target then
            return target
        end

        -- Wrap pointer coordinates
        local wrap_px, wrap_py = curr_item.x, curr_item.y

        if dx ~= 0 then
            wrap_px = (dx > 0) and 0 or screenwidth
        end
        if dy ~= 0 then
            wrap_py = (dy > 0) and 0 or screenheight
        end

        return self:search(curr_item, wrap_px, wrap_py, items, dx, dy)
    end

    function level:search(curr_item, cx, cy, items, dx, dy)
        local best_button = nil
        local best_score = nil

        for _, b in ipairs(items) do
            if b == curr_item then goto continue end
            local bx, by = b.x + b.w / 2, b.y + b.h / 2
            local vx, vy = bx - cx, by - cy

            -- Dot product to check alignment with direction
            local dot = vx * dx + vy * dy
            if dot <= 0 then goto continue end -- wrong direction

            -- Normalize to direction alignment score (cosine similarity)
            local mag_v = sqrt(vx * vx + vy * vy)
            local mag_d = sqrt(dx * dx + dy * dy)
            local angle_cos = dot / (mag_v * mag_d)

            -- Distance is used to favor closer matches
            local distance = mag_v

            -- Combine angle closeness and distance
            local score = distance / angle_cos -- lower is better

            if not best_score or score < best_score then
                best_score = score
                best_button = b
            end
            ::continue::
        end

        return best_button
    end

    level:init()
    level:recalc_active_buttons()
    level:recalc_is_hover()
    return level
end