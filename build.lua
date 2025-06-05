local input_cart = "cart.p8"
local output_cart = "build.p8"

local function get_lua_files()
    local files = {}
    for filename in io.popen('ls src/*.lua'):lines() do
        table.insert(files, filename)
    end
    table.sort(files)
    -- optional: ensure consistent order
    return files
end

-- Your Lua source files in order
local lua_sources = get_lua_files()

-- Read template cart
local input = assert(io.open(input_cart, "r"))
local content = input:read("*a")
input:close()

-- Read all source files and concatenate
local function get_combined_lua()
    local result = {}
    for _, filename in ipairs(lua_sources) do
        local file = assert(io.open(filename, "r"))
        table.insert(result, file:read("*a"))
        file:close()
    end
    return table.concat(result, "\n")
end

-- Replace __lua__ section
local lua_code = get_combined_lua()

-- Pattern to find the __lua__ section and everything after
local before, after = content:match("^(.-)__lua__.-\n(.*)$")
local gfx_split = after:find("__gfx__")
local remaining = gfx_split and after:sub(gfx_split - 1) or ""

-- Write new cart
local output = assert(io.open(output_cart, "w"))
output:write(before)
output:write("__lua__\n")
output:write(lua_code)
output:write("\n")
output:write(remaining)
output:close()

print("✅ Built cart to " .. output_cart)