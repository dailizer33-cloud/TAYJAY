-- TAYJAY CLEANUP CORE V1: ResourceManager -> Owner -> Bag.
local function cleanupBagItem(obj)
    local objectType = typeof(obj)
    if objectType == "RBXScriptConnection" then obj:Disconnect()
    elseif objectType == "Instance" then obj:Destroy()
    elseif type(obj) == "function" then obj() end
end
local function newBag()
    local items, bag = {}, { Cleaned = false }
    function bag:Add(obj)
        if obj == nil then return obj end
        if self.Cleaned then pcall(cleanupBagItem, obj); return obj end
        items[#items + 1] = obj
        return obj
    end
    function bag:Clean()
        if self.Cleaned then return false end
        self.Cleaned = true
        for i = #items, 1, -1 do
            local obj = items[i]; items[i] = nil
            local ok, err = pcall(cleanupBagItem, obj)
            if not ok then warn("[TAYJAY CleanupBag] " .. tostring(err)) end
        end
        return true
    end
    function bag:Reset()
        if not self.Cleaned then return false end
        self.Cleaned = false
        return true
    end
    function bag:Count() return #items end
    return bag
end
local function newCleanupOwner(ownerId, onStop)
    local owner = { Id = ownerId, Stopped = false, Bag = newBag() }
    function owner:OwnBag(bag)
        if type(bag) ~= "table" or type(bag.Clean) ~= "function" then return false end
        self.Bag:Add(function() bag:Clean() end)
        return true
    end
    function owner:Stop()
        if self.Stopped then return false end
        self.Stopped = true
        if type(onStop) == "function" then
            local ok, err = pcall(onStop)
            if not ok then warn("[TAYJAY Owner] " .. self.Id .. ": " .. tostring(err)) end
        end
        self.Bag:Clean()
        return true
    end
    return owner
end
function ResourceManager:RegisterOwner(ownerId, owner)
    if type(ownerId) ~= "string" or type(owner) ~= "table" or type(owner.Stop) ~= "function" then return false end
    if self.Owners[ownerId] ~= nil then return false end
    self.Owners[ownerId] = owner
    return true
end
function ResourceManager:StopOwner(ownerId)
    local owner = self.Owners[ownerId]
    if not owner then return false end
    return owner:Stop()
end
ResourceManager.Owners = {}

