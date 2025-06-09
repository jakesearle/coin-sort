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

function split_into_parts(list, n)
    local parts = {}
    local total = #list
    local size = ceil(total / n)

    for i = 1, total, size do
        local part = {}
        for j = i, min(i + size - 1, total) do
            add(part, list[j])
        end
        add(parts, part)
    end

    return parts
end

function flatten(tbl)
    local flat = {}
    for _, sub in ipairs(tbl) do
        for _, val in ipairs(sub) do
            add(flat, val)
        end
    end
    return flat
end

function extend(a, b)
    for _, v in ipairs(b) do
        add(a, v)
    end
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
    assert(count ~= 0, "average_y: coin list is empty")

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
    s = remove_leading_zeros(s)
    return s
end

function remove_leading_zeros(s)
    local i = 1
    while s[i] == "0" and i < #s do
        i += 1
    end
    s = sub(s, i)
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