function make_game()
    local game = {
        f = 0,
        f_gameover = nil,
        state = GAME_STATE.main_menu,
        children = {}
    }

    function game:init_sysmenu()
        local menu_items = {
            {
                text = "main menu",
                callback = function() self:_start_menu() end
            },
            {
                text = "reset high score",
                callback = function() self:_reset_high_score() end
            },
        }
        for i, mi in ipairs(menu_items) do
            menuitem(i, mi.text, mi.callback)
        end
        self:_start_menu()
    end

    function game:update()
        if self.state == GAME_STATE.level and self.children[1]:is_gameover() then
            self.state = GAME_STATE.game_over_countdown
            self.f_gameover = self.f
        elseif self.state == GAME_STATE.game_over_countdown then
            if self.f == (TIME.second * 2) + self.f_gameover then
                self:_start_gameover()
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

    function game:_start_menu()
        self.state = GAME_STATE.main_menu
        local f = function() self:_start_level() end
        self.children = { make_menu(f) }
    end

    function game:_start_level()
        self.state = GAME_STATE.level
        self.children = { make_level(level1) }
    end

    function game:_start_gameover()
        self.state = GAME_STATE.game_over
        local f1 = function() self:_start_menu() end
        local f2 = function() self:_start_restart() end

        add(self.children, make_popup("game over", f1, f2))
    end

    function game:_reset_high_score()
        save_big_number("0")
        if self.state == GAME_STATE.level then
            self.children[1]:fetch_highscore()
        end
    end

    function game:_start_restart()
        self:_start_level()
    end

    game:init_sysmenu()
    return game
end