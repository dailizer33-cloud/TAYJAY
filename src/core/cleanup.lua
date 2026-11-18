-- TAYJAY CLEANUP CORE V2: ResourceManager -> Owner -> Bag.
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
    function bag:AddTask(thread)
        if thread == nil then return nil end
        self:Add(function()
            if type(task) == "table" and type(task.cancel) == "function" then pcall(task.cancel, thread) end
        end)
        return thread
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
    local owner = { Id = ownerId, Stopped = false, Cancelled = false, Token = { Cancelled = false }, Bag = newBag() }
    function owner:IsAlive() return not self.Stopped and not self.Cancelled end
    function owner:OwnBag(bag)
        if type(bag) ~= "table" or type(bag.Clean) ~= "function" then return false end
        self.Bag:Add(function() bag:Clean() end)
        return true
    end
    function owner:Own(obj) self.Bag:Add(obj); return obj end
    function owner:Stop(reason)
        if self.Stopped then return false end
        self.Stopped, self.Cancelled, self.StopReason = true, true, reason
        self.Token.Cancelled = true
        if type(onStop) == "function" then
            local ok, err = pcall(onStop, reason)
            if not ok then warn("[TAYJAY Owner] " .. tostring(self.Id) .. ": " .. tostring(err)) end
        end
        self.Bag:Clean()
        return true
    end
    return owner
end
ResourceManager.Owners = ResourceManager.Owners or {}
function ResourceManager:RegisterOwner(ownerId, owner)
    if type(ownerId) ~= "string" or ownerId == "" or type(owner) ~= "table" or type(owner.Stop) ~= "function" then return false end
    local existing = self.Owners[ownerId]
    if existing and existing ~= owner and existing.Stopped ~= true then return false end
    self.Owners[ownerId] = owner
    return true
end
function ResourceManager:StopOwner(ownerId, reason)
    local owner = self.Owners[ownerId]
    if not owner then return false end
    local ok, result = pcall(owner.Stop, owner, reason)
    if self.Owners[ownerId] == owner then self.Owners[ownerId] = nil end
    if not ok then warn("[TAYJAY ResourceManager] StopOwner " .. tostring(ownerId) .. ": " .. tostring(result)); return false end
    return result ~= false
end
function ResourceManager:GetOwnerStatus()
    local result = {}
    for id, owner in pairs(self.Owners) do
        result[id] = { stopped = owner.Stopped == true, cancelled = owner.Cancelled == true,
            resources = owner.Bag and owner.Bag.Count and owner.Bag:Count() or 0 }
    end
    return result
end
