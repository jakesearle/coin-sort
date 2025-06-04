function _init()
    printh("\nSTART:")
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