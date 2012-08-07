local http = require 'socket.http'
local replace = {
    ["&"] = "%26",
    ["#"] = "%23",
    ["?"] = "%3F",
    ["="] = "%3D",
    ["+"] = "%2B",
    ["<"] = "%3C",
    [">"] = "%3E",
    ["@"] = "%40",
    ["%"] = "%25",
    [" "] = "+"
}

function parsesubs(get)
    local rt = {}

    for m in get:gmatch("<pod(.-)</pod>") do
        local r = ""
        if not m:find("<plaintext/>") then
            local title = m:match("title=\'(.-)\'")
            local value = m:match("<plaintext>(.-)</plaintext>")
            if value ~= "" then
                r = r .. "" .. title .. " : " .. value .. "    "
                table.insert(rt, r)
            end
        end
    end

    return rt
end

local msg, from, level = ...
msg = msg:gsub("(.)", function(d) return replace[d] or d end)

local url     = "http://www.wolframalpha.com/input/?i=" .. msg:gsub("(.)", function(d) return d or replace[d] end)
local get     = http.request("http://api.wolframalpha.com/v2/query?input=" .. msg .. "&appid=4W38Y3-24ELW49Y9U&format=plaintext")
local returns = "Error: could not resolve output" --oh my how embarrasing
local related

if get:find("<relatedexample input=\'") then
    related = get:match("<relatedexample input=\'(.-)\'") or "error: could not resolve relatedexample"
    returns = "Could not be found. Did you mean: \"" .. related .. "\"?"
else
    returns = parsesubs(get)
    if #returns < 0 then
        returns = "error: could not find related example to given input."
    end
end

if type(returns) == "table" then
    local q = from .. ": " .. url
    for i,x in pairs(returns) do
        if #x + #q > 400 then
            --return(q)
            q = "[ "..x:sub(1,-4).."]"
        else
            q = q.."   [ "..x:sub(1,-4).."]"
        end
    end
    return(q)
else
    return(from .. ": " .. url .. " : " .. returns)
end