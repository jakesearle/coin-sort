debug_slowdown = 1

function _init()
    printh("\nSTART:")
    frame = 0
    prev_btn = 0
    game = make_game()
end

function _update()
    frame += 1
    if frame % debug_slowdown == 0 then
        game:update()
        update_prev_btn()
    end
end

function _draw()
    -- Background
    if frame % debug_slowdown == 0 then
        cls(15)
        game:draw()
        -- big_print("text", 50, 50, 11)
    end
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