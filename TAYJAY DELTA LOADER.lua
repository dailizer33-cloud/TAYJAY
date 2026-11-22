-- TAYJAY DELTA LOADER
-- Robust HTTP + compiler checks for Delta Android and compatible executors.
-- This loader never blindly calls a missing HTTP or compile function.

local URL = "https://raw.githubusercontent.com/dailizer33-cloud/TAYJAY/fix/delta-loader-runtime-guard/TAYJAY%20MAIN.lua"

local function getEnvironment()
    local env = _G
    local getter = rawget(_G, "getgenv")
    if type(getter) == "function" then
        local ok, shared = pcall(getter)
        if ok and type(shared) == "table" then
            env = shared
        end
    end
    return env
end

local function report(message)
    local text = "[TAYJAY LOADER] " .. tostring(message)
    pcall(function() warn(text) end)
    pcall(function() print(text) end)
end

local env = getEnvironment()

local function fetchWithGameHttp()
    local httpGet
    pcall(function() httpGet = game.HttpGet end)
    if type(httpGet) ~= "function" then
        return nil, "game:HttpGet is unavailable"
    end
    local ok, body = pcall(function()
        return game:HttpGet(URL)
    end)
    if not ok then
        return nil, "game:HttpGet failed: " .. tostring(body)
    end
    if type(body) ~= "string" or body == "" then
        return nil, "game:HttpGet returned an empty response"
    end
    return body
end

local function fetchWithRequest()
    local requestFn = env.request
    if type(requestFn) ~= "function" then requestFn = env.http_request end
    if type(requestFn) ~= "function" and type(env.syn) == "table" then
        requestFn = env.syn.request
    end
    if type(requestFn) ~= "function" then
        return nil, "No supported HTTP request function was found"
    end
    local ok, response = pcall(requestFn, {
        Url = URL,
        Method = "GET",
    })
    if not ok then
        return nil, "HTTP request failed: " .. tostring(response)
    end
    if type(response) ~= "table" then
        return nil, "HTTP request returned an invalid response"
    end
    local status = tonumber(response.StatusCode or response.Status)
    if status and (status < 200 or status >= 300) then
        return nil, "HTTP status " .. tostring(status)
    end
    local body = response.Body or response.body
    if type(body) ~= "string" or body == "" then
        return nil, "HTTP response body is empty"
    end
    return body
end

local source, httpError = fetchWithGameHttp()
if not source then
    source, httpError = fetchWithRequest()
end
if not source then
    report("DOWNLOAD FAILED. " .. tostring(httpError))
    report("Check Delta HTTP permissions/network, then execute this loader again.")
    return
end

local compiler = env.loadstring or rawget(_G, "loadstring")
if type(compiler) ~= "function" then
    report("COMPILE FAILED. loadstring is unavailable in this executor.")
    report("Update/reinstall Delta or enable its script compilation support.")
    return
end

local compileOk, chunk, compileError = pcall(compiler, source)
if not compileOk then
    report("COMPILE FAILED: " .. tostring(chunk))
    return
end
if type(chunk) ~= "function" then
    report("COMPILE FAILED: " .. tostring(compileError or "compiler returned no function"))
    return
end

report("Download and compile successful. Starting TAYJAY MAIN.")
local runOk, runError = pcall(chunk)
if not runOk then
    report("MAIN RUNTIME ERROR: " .. tostring(runError))
end
