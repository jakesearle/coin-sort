function hcenter(s)
    -- string length times the
    -- pixels in a char's width
    -- cut in half and rounded down
    return (screenwidth / 2) - flr((#s * 4) / 2)
end

function vcenter(s)
    -- string char's height
    -- cut in half and rounded down
    return (screenheight / 2) - flr(5 / 2)
end

--- collision check
function is_colliding(obj1, obj2)
    local x1 = obj1.x
    local y1 = obj1.y
    local w1 = obj1.w
    local h1 = obj1.h

    local x2 = obj2.x
    local y2 = obj2.y
    local w2 = obj2.w
    local h2 = obj2.h

    if (x1 < (x2 + w2) and (x1 + w1) > x2 and y1 < (y2 + h2) and (y1 + h1) > y2) then
        return true
    else
        return false
    end
end

function is_even(n)
    return n % 2 == 0
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

function contains(list, item)
    for value in all(list) do
        if value == item then
            return true
        end
    end
    return false
end

function approx_eq(a, b, tolerance)
    tolerance = tolerance or 0.1
    return abs(a - b) < tolerance
end

function btnr(btn_id)
    return ((prev_btn & (1 << btn_id)) > 0) and (btn(btn_id) == false)
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

-- pancelor's pq-debugging

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

function center_xy(item)
    return item.x + (item.w \ 2), item.y + (item.h \ 2)
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

function draw_all(list)
    for x in all(list) do
        if type(x.draw) == "function" then
            x:draw()
        end
    end
end

function print_centered(text, x, y, w, h, color)
    -- text width (4 pixels per char)
    local tw = #text * 4
    -- centered x
    local tx = x + (w - tw) / 2
    -- centered y (6 px tall font)
    local ty = y + (h - 6) / 2
    -- default color white (7)
    print(text, tx, ty, color or 7)
end

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

function n_keys(t)
    local count = 0
    for k, _ in pairs(t) do
        count += 1
    end
    return count
end