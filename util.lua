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