function make_game()
    local game = {
        level = make_level(level1),
        popup = nil,
        state = GAME_STATE.level,
        f = 0,
        f_gameover = nil
    }

    function game:update()
        if self.state == GAME_STATE.level then
            self.level:update()
            if self.level:is_gameover() then
                self.state = GAME_STATE.game_over_countdown
                self.f_gameover = self.f
            end
        elseif self.state == GAME_STATE.game_over_countdown then
            self.level:update()
            -- if self.f >= (TIME.second * 2) + self.f_gameover then
            self.state = GAME_STATE.game_over
            -- end
        elseif self.state == GAME_STATE.game_over then
            if self.popup == nil then
                self.popup = make_popup("game over", self.main_menu, self.restart)
            end
            self.popup:update()
        end
        self.f += 1
    end

    function game:draw()
        self.level:draw()
        if self.popup then
            self.popup:draw()
        end
    end

    function game:main_menu()
        printh("Main menu")
    end

    function game:restart()
        printh("Restart")
    end

    return game
end