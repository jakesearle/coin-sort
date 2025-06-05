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