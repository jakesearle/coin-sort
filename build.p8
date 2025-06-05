pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function make_button(x, y, button_type)
    local color, text
    if button_type == LEVEL_CONFIG.BUTTON_TYPES.merge then
        color = 11
        text = "merge 🅾️"
    elseif button_type == LEVEL_CONFIG.BUTTON_TYPES.deal then
        color = 12
        text = "deal"
    elseif button_type == LEVEL_CONFIG.BUTTON_TYPES.restart then
        color = 11
        text = "restart"
    elseif button_type == LEVEL_CONFIG.BUTTON_TYPES.main_menu then
        color = 12
        text = "main menu"
    end
    button = {
        button_type = button_type,
        x = x,
        y = y,
        h = LEVEL_CONFIG.BUTTON.height,
        w = LEVEL_CONFIG.BUTTON.width,
        color = color,
        text = text,
        is_pressed = false,
        is_enabled = true
    }

    function button:draw()
        local body = self:get_body_color()
        local shadow = self:get_shadow(self.color)
        local highlight = self:get_highlight(self.color)
        if self.is_pressed then
            local tmp = shadow
            shadow = highlight
            highlight = tmp
        end
        rectfill(self.x, self.y, self.x + self.w, self.y + self.h, body)
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

    function button:get_body_color()
        if self.is_enabled then return self.color end
        return 6
    end

    function button:get_highlight(color)
        if not self.is_enabled then return 5 end
        if color == 11 or color == 12 then return 7 end
    end

    function button:get_shadow(color)
        if not self.is_enabled then return 5 end
        if color == 12 then return 1 end
        if color == 11 then return 3 end
    end

    return button
end
-- Bad Colors:
-- 5 - Slot color
-- 6 - Tray color
-- 15 - Background Color

-- Pairs:
-- 0 & 7 - Black and white
-- 1 & 12 - Navy and Blue
-- 2 & 8 - Maroon & Red
-- 3 & 11 - Forest & Lime
-- 4 & 9 - Brown & Orange
COLOR_PAIRS = {
    { 8, 2 },
    { 9, 4 },
    { 10, 9 },
    { 11, 3 },
    { 12, 1 },
    { 14, 2 },
    { 7, 0 }
}

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
        local blank_spr = 9
        local pallette_i = ((self.value - 1) % #COLOR_PAIRS) + 1
        local should_flip = not is_even((self.value - 1) \ #COLOR_PAIRS)
        local light, dark = COLOR_PAIRS[pallette_i][1], COLOR_PAIRS[pallette_i][2]

        if should_flip then
            light, dark = dark, light
        end

        pal(1, light)
        pal(2, dark)
        spr(blank_spr, self.x, self.y)
        pal()

        local n_digits = #tostr(abs(self.value))
        if n_digits == 1 then
            print(self.value, self.x + 3, self.y + 2, dark)
        elseif n_digits == 2 then
            local l, r = tostr(abs(self.value))[1], tostr(abs(self.value))[2]
            print(l, self.x + 1, self.y + 2, dark)
            print(r, self.x + 4, self.y + 2, dark)
        end
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
-- global vars
screenwidth = 127
screenheight = 127

level1 = {
    {},
    {},
    {},
    {},
    {},
    {},
    {},
    {},
    {},
    {}
}

GAME_STATE = {
    menu = 1,
    level = 2,
    game_over_countdown = 3,
    game_over = 4
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
        merge = 2,
        restart = 3,
        main_menu = 4
    },
    BUTTON = {
        height = 10,
        width = 40,
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
function make_game()
    local game = {
        f = 0,
        f_gameover = nil,
        state = GAME_STATE.main_menu,
        children = {}
    }

    function game:init_menuitems()
        local menu_items = {
            {
                text = "main menu",
                callback = function() self:start_menu() end
            }
        }
        for i, mi in ipairs(menu_items) do
            menuitem(i, mi.text, mi.callback)
        end
    end

    function game:update()
        if self.state == GAME_STATE.level and self.children[1]:is_gameover() then
            self.state = GAME_STATE.game_over_countdown
            self.f_gameover = self.f
        elseif self.state == GAME_STATE.game_over_countdown then
            if self.f == (TIME.second * 2) + self.f_gameover then
                self:start_gameover()
            end
        end

        for c in all(self.children) do
            c:update()
        end

        self.f += 1
    end

    function game:draw()
        draw_all(self.children)
    end

    function game:start_menu()
        self.state = GAME_STATE.main_menu
        local f = function() self:start_level() end
        self.children = { make_menu(f) }
    end

    function game:start_level()
        self.state = GAME_STATE.level
        self.children = { make_level(level1) }
    end

    function game:start_gameover()
        self.state = GAME_STATE.game_over
        local f1 = function() self:start_menu() end
        local f2 = function() self:start_restart() end

        self.children = { make_popup("game over", f1, f2) }
    end

    function game:start_restart()
        self:start_level()
    end

    game:init_menuitems()
    game:start_menu()
    return game
end
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
        state = LEVEL_STATE.hovering,
        high_score = load_big_number(),
        score = make_bigint(0)
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
            elseif btnp(🅾️) then
                self:merge_button_down()
            elseif btnr(🅾️) then
                self:merge_button_up()
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

        self:update_children()
    end

    function level:draw()
        local go = self:is_gameover()
        draw_all(self.trays)
        if not go then
            draw_all(self.buttons)
        end

        self:_draw_score()

        -- Draw releasing coins on top
        for tray in all(self.trays) do
            for c in all(tray.coins) do
                if c.state == COIN_STATE.releasing then
                    c:draw()
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
        y = y + h + 1
        w, _ = text_size(score_val)
        x = screenwidth - w + 1
        print(score_val, x, y)

        print("best", 1, 1)
        print(format_bigint(self.high_score))
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
        self:recalc_active_buttons()
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
                local big_i = make_bigint(t:get_last_val())
                printh(big_i)
                local sub_total = mult_bigint(big_i, big_i) .. "00"
                printh(sub_total)
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
        self:recalc_active_buttons()
    end

    function level:dealable_coins()
        local ccs = self:current_coins()
        local n_types = n_keys(ccs)
        local min_types = #self.trays - 1
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

    function level:recalc_active_buttons()
        local can_merge = false
        for t in all(self.trays) do
            if t.is_complete then
                can_merge = true
                break
            end
        end

        for b in all(self.buttons) do
            if b.button_type == LEVEL_CONFIG.BUTTON_TYPES.merge then
                b.is_enabled = can_merge
            end
        end
    end

    function level:is_gameover()
        for t in all(self.trays) do
            if t.is_complete then
                return false
            end
            if t:empty_slots() > 0 then
                return false
            end
        end

        return true
    end

    level:recalc_active_buttons()
    return level
end
function _init()
    printh("\nSTART:")
    cartdata("my_game_save")
    -- save_big_number("0")
    frame = 0
    prev_btn = 0
    game = make_game()
end

function _update()
    frame += 1
    game:update()
    update_prev_btn()
end

function _draw()
    -- Background
    cls(15)
    game:draw()
end

function update_prev_btn()
    -- Update previous button for btnr (button release)
    prev_btn = 0
    for i = 0, 5 do
        if btn(i) then
            prev_btn |= (1 << i)
        end
    end
end
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
function make_pointer(i, x, y)
    pointer = {
        tray_i = i, -- which tray I'm pointing to
        button_i = nil, -- which button I'm pointing to
        prev_tray_i = nil,
        prev_button_i = nil,
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

    function pointer:move_to_tray(i, nx, ny)
        self.tray_i = i
        self.prev_button_i = self.button_i
        self.button_i = nil
        self.tx = nx
        self.ty = ny
    end

    function pointer:move_to_button(i, nx, ny)
        self.prev_tray_i = self.tray_i
        self.tray_i = nil
        self.button_i = i
        self.tx = nx
        self.ty = ny
    end

    function pointer:grab(coins)
        self.coins_from = self.tray_i
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
        if self.tray_i == nil and self.button_i == nil then
            error("Both pointer i variables are unset")
        elseif self.tray_i ~= nil and self.button_i ~= nil then
            error("Both pointer i variables are set")
        end
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
                self.pointer = make_pointer(nil, x, y)
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

    function popup:_move_pointer(dir)
        local new_i = ((self.pointer.button_i - 1 + dir) % #self.buttons) + 1
        local new_x, new_y = self.buttons[new_i]:get_pointer_xy()
        self:_get_pointed_button():release()
        self.pointer:move_to_button(new_i, new_x, new_y)
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

    function popup:draw()
        -- Shadow
        squircle_fill(self.x + 4, self.y + 4, self.w, self.h, self.r_squircle, 0)
        -- Border
        squircle_fill(self.x, self.y, self.w, self.h, self.r_squircle, 2)
        -- Body
        squircle_fill(self.x + 1, self.y + 1, self.w - 2, self.h - 2, self.r_squircle, 15)
        self:_draw_header()
        -- draw_outline(self.button_container)
        self:_draw_buttons()
        if self.pointer then
            self.pointer:draw()
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

    function popup:_draw_buttons()
        local total_button_w = #self.buttons * self.buttons[1].w
        if self.button_container.w >= total_button_w then
            draw_all(self.buttons)
        end
    end

    function popup:_get_pointed_button()
        return self.buttons[self.pointer.button_i]
    end

    popup:init()
    return popup
end
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
            local x, y = self:xy_for_slot(i)
            local coin = make_coin(x, y, val)
            add(coins, coin)
        end
        self.coins = coins
        self:calc_is_complete()
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
        self:calc_is_complete()
    end

    function tray:empty_slots()
        return TRAY_CONFIG.n_slots - #self.coins
    end

    function tray:drop_into(dropped_coins, post_anim_state)
        local starting_i = #self.coins
        for i, c in ipairs(dropped_coins) do
            -- add the data
            local x, y = self:xy_for_slot(starting_i + i)
            c:release(x, y, starting_i + i, post_anim_state)
            add(self.coins, c)
        end
        self:calc_is_complete()
    end

    function tray:xy_for_slot(i)
        return self.x + 1, self.y - 3 + ((i - 1) * 2)
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

    function tray:calc_is_complete()
        self.is_complete = all_vals_eq(self.coins)
    end

    function tray:move_coins_up()
        local x, y = self:xy_for_slot(1)
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
----------
-- DRAW --
----------
function draw_all(list)
    for x in all(list) do
        if type(x.draw) == "function" then
            x:draw()
        end
    end
end

function squircle_fill(x, y, w, h, r, c)
    rectfill(x + r, y, x + w - r, y + h, c)
    rectfill(x, y + r, x + w, y + h - r, c)
    circfill(x + r, y + r, r, c)
    circfill(x + w - r, y + r, r, c)
    circfill(x + r, y + h - r, r, c)
    circfill(x + w - r, y + h - r, r, c)
end

function draw_outline(obj, color)
    color = color or obj.c or obj.color or 14
    assert(obj.x ~= nil, "'obj.x' must not be nil")
    assert(obj.y ~= nil, "'obj.y' must not be nil")
    assert(obj.w ~= nil, "'obj.w' must not be nil")
    assert(obj.h ~= nil, "'obj.h' must not be nil")
    rect(obj.x, obj.y, obj.x + obj.w, obj.y + obj.h, color)
end

-----------
-- INPUT --
-----------
function btnr(btn_id)
    return ((prev_btn & (1 << btn_id)) > 0) and (btn(btn_id) == false)
end

---------------
-- LIST UTIL --
---------------
function contains(list, item)
    for value in all(list) do
        if value == item then
            return true
        end
    end
    return false
end

function index_of(list, item)
    for i = 1, #list do
        if list[i] == item then
            return i
        end
    end
    -- not found
    return nil
end

function remove_items(list, to_remove)
    for i = #list, 1, -1 do
        for item in all(to_remove) do
            if list[i] == item then
                deli(list, i)
                break
            end
        end
    end
end

function split_list(list, first_len)
    local first = {}
    local second = {}

    for i = 1, #list do
        if i <= first_len then
            add(first, list[i])
        else
            add(second, list[i])
        end
    end

    return first, second
end

-------------
-- LOGGING --
-------------
-- quote all args and print to host console
-- usage:
--   pq("handles nils", many_vars, {tables=1, work=11, too=111})
function pq(...)
    printh(qq(...))
    return ...
end

-- quote all arguments into a string
-- usage:
--   x=2 y=3 ?qq("x=",x,"y=",y)
function qq(...)
    local s, args = "", pack(...)
    for i = 1, args.n do
        s ..= quote(args[i]) .. " "
    end
    return s
end

-- quote a single thing
-- like tostr() but for tables
-- don't call this directly; call pq or qq instead
function quote(t, depth)
    depth = depth or 4
    --avoid inf loop
    if type(t) ~= "table" or depth <= 0 then return tostr(t) end

    local s = "{"
    for k, v in pairs(t) do
        s ..= tostr(k) .. "=" .. quote(v, depth - 1) .. ","
    end
    return s .. "}"
end

-- like sprintf (from c)
-- usage:
--   ?qf("%/% is %%",3,8,3/8*100,"%")
function qf(fmt, ...)
    local parts, args = split(fmt, "%"), pack(...)
    local str = deli(parts, 1)
    for ix, pt in ipairs(parts) do
        str ..= quote(args[ix]) .. pt
    end
    if args.n ~= #parts then
        -- uh oh! mismatched arg count
        str ..= "(extraqf:" .. (args.n - #parts) .. ")"
    end
    return str
end
function pqf(...) printh(qf(...)) end

function nearest_item(items, x, y)
    local nearest = nil
    local min_dist = nil

    for i in all(items) do
        local c_x, c_y = center_xy(i)
        local dx = c_x - x
        local dy = c_y - y
        local dist = dx * dx + dy * dy -- use squared distance (faster)

        if not min_dist or dist < min_dist then
            min_dist = dist
            nearest = i
        end
    end

    return nearest
end

--------------
-- MAP UTIL --
--------------
function n_keys(t)
    local count = 0
    for k, _ in pairs(t) do
        count += 1
    end
    return count
end

----------
-- MATH --
----------
function approx_eq(a, b, tolerance)
    tolerance = tolerance or 0.1
    return abs(a - b) < tolerance
end

function average_y(list_of_coins)
    local total = 0
    local count = #list_of_coins

    if count == 0 then
        error("average_y: coin list is empty")
    end

    for coin in all(list_of_coins) do
        total += coin.y
    end

    return total / count
end

function center_xy(item)
    return item.x + (item.w \ 2), item.y + (item.h \ 2)
end

function is_even(n)
    return n % 2 == 0
end

function make_bigint(num)
    return tostr(num)
end

function add_bigint(a, b)
    local result = ""
    local carry = 0

    local i = #a
    local j = #b

    while i > 0 or j > 0 or carry > 0 do
        local digit_a = i > 0 and tonum(sub(a, i, i)) or 0
        local digit_b = j > 0 and tonum(sub(b, j, j)) or 0

        local sum = digit_a + digit_b + carry
        carry = flr(sum / 10)
        result = (sum % 10) .. result

        i -= 1
        j -= 1
    end

    return result
end

function mult_bigint(a, b)
    local result = {}
    local len_a = #a
    local len_b = #b

    -- Initialize result array
    for i = 1, len_a + len_b do
        result[i] = 0
    end

    -- Reverse loop through digits of a and b
    for i = len_a, 1, -1 do
        local digit_a = tonum(sub(a, i, i))
        for j = len_b, 1, -1 do
            local digit_b = tonum(sub(b, j, j))
            local pos = i + j
            result[pos] += digit_a * digit_b
        end
    end

    -- Handle carries
    for i = #result, 2, -1 do
        local carry = flr(result[i] / 10)
        result[i] %= 10
        result[i - 1] += carry
    end

    -- Convert to string
    local out = ""
    local leading = true
    for i = 1, #result do
        if leading and result[i] == 0 then
            -- skip leading zero
        else
            leading = false
            out ..= result[i]
        end
    end

    return out == "" and "0" or out
end

function format_bigint(n_str)
    local suffixes = { "", "k", "m", "b", "t" }

    -- remove leading zeros
    while sub(n_str, 1, 1) == "0" and #n_str > 1 do
        n_str = sub(n_str, 2)
    end

    local len = #n_str
    local group = flr((len - 1) / 3)
    local suffix = suffixes[group + 1] or ("e" .. (group * 3))

    local digits = len - group * 3

    local prefix = sub(n_str, 1, digits)
    local decimal = sub(n_str, digits + 1, digits + 1)
    if decimal != "" and decimal != "0" then
        return prefix .. "." .. decimal .. suffix
    else
        return prefix .. suffix
    end
end

function gt_bigint(a, b)
    -- Compare by length first
    if #a > #b then
        return true
    elseif #a < #b then
        return false
    end

    -- Length is the same, compare digit by digit
    for i = 1, #a do
        local da = ord(sub(a, i, i))
        local db = ord(sub(b, i, i))
        if da > db then
            return true
        elseif da < db then
            return false
        end
    end

    -- Equal
    return false
end

------------
-- RANDOM --
------------
function random_item(list)
    if #list == 0 then return nil end
    return list[flr(rnd(#list)) + 1]
end

function random_key(dict)
    local keys = {}
    for k, _ in pairs(dict) do
        add(keys, k)
    end
    return random_item(keys)
end

-------------
-- STORAGE --
-------------

function save_big_number(s)
    -- break into chunks of 4 digits from the back
    local chunks = {}
    while #s > 0 do
        local chunk = sub(s, max(1, #s - 3), #s)
        add(chunks, chunk)
        s = sub(s, 1, #s - #chunk)
    end

    -- save each chunk into dset
    for i, chunk in ipairs(chunks) do
        printh(chunk)
        dset(i, tonum(chunk))
    end

    -- optionally store how many chunks were saved
    dset(0, #chunks)
end

function load_big_number()
    local len = dget(0)
    if len == 0 then return "0" end
    local s = ""
    for i = 1, len do
        local chunk = tostr(flr(dget(i)))
        -- Pad the chunk with leading zeros if needed
        if i > 1 then
            while #chunk < 4 do
                chunk = "0" .. chunk
            end
        end
        s = chunk .. s
    end
    return s
end

----------
-- TEXT --
----------
function big_print(text, x, y, color)
    assert(text ~= nil, "'text' must not be nil")
    assert(x ~= nil, "'x' must not be nil")
    assert(y ~= nil, "'y' must not be nil")
    assert(color ~= nil, "'color' must not be nil")
    print("\^w\^t" .. text, x, y, color)
end

function print_centered(text, x, y, w, h, color)
    color = color or 0
    local tw, th = text_size(text)
    local tx = (w - tw) / 2 + x
    local ty = (h - th) / 2 + y
    print(text, tx, ty, color)
end

function text_size(text)
    local offscreen_offset = -100
    local x, y = print(text, 0, offscreen_offset)
    return x, y - offscreen_offset
end

function format_commas(n)
    local s = "" .. n
    local out = ""
    local i = 0

    for j = #s, 1, -1 do
        i += 1
        out = sub(s, j, j) .. out
        if i % 3 == 0 and j > 1 then
            out = "," .. out
        end
    end

    return out
end

__gfx__
0000000002222220044444400999999003333330011111100dddddd0088888800999999002222220000000000000000000000000000000000000000000000000
0000000028888882499999949aaaaaa93bbbbbb31cccccc1deeeeeed822222289444444921111112000000000000000000000000000000000000000000000000
007007008882288899444499aa9999aabb3bb3bbcc1111cceeddddee228888224499994411111111000000000000000000000000000000000000000000000000
000770008888288899999499aaaaa9aabb3bb3bbcc1ccccceedeeeee222228224494494411111111000000000000000000000000000000000000000000000000
000770008888288899444499aaa999aabb3333bbcc1111cceeddddee222282224449944411111111000000000000000000000000000000000000000000000000
007007008888288899499999aaaaa9aabbbbb3bbccccc1cceedeedee222822224494494411111111000000000000000000000000000000000000000000000000
000000008882228899444499aa9999aabbbbb3bbcc1111cceeddddee222822224499994411111111000000000000000000000000000000000000000000000000
0000000008888880099999900aaaaaa00bbbbbb00cccccc00eeeeee0022222200444444001111110000000000000000000000000000000000000000000000000
000555000005550000055500ffffffff011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005777500057775000577750f76d510f1cccccc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
057777750577777505777775ffffffffc111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05777775557777750577777500000000ccc11c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05757575057575700575757500000000c1111c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05755550005555500575757500000000c1cc1c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05750000000000000050505000000000c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005000000000000000000000000000000cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
