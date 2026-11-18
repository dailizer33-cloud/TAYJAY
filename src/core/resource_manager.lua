-- =========================================================
-- TAYJAY RESOURCE MANAGER V2 — PERSISTENT MONITOR MODE
-- Observes declared writes only. It never acquires, blocks, preempts,
-- or changes the behavior of a registered feature.
-- =========================================================
local _tjRMEnv = _G
pcall(function()
    if type(getgenv) == "function" then
        local shared = getgenv()
        if type(shared) == "table" then _tjRMEnv = shared end
    end
end)
local TJ = _tjRMEnv.TJ
if type(TJ) ~= "table" then TJ = {}; _tjRMEnv.TJ = TJ end
local ResourceManager = TJ.ResourceManager
if type(ResourceManager) ~= "table" then ResourceManager = {}; TJ.ResourceManager = ResourceManager end
-- Preserve active owner registrations and diagnostic history on re-execution.
ResourceManager.Mode = "MONITOR"
ResourceManager.Modules = ResourceManager.Modules or {}
ResourceManager.RecentWrites = ResourceManager.RecentWrites or {}
ResourceManager.LastConflictAt = ResourceManager.LastConflictAt or {}
ResourceManager.Conflicts = ResourceManager.Conflicts or {}
ResourceManager.TotalWrites = tonumber(ResourceManager.TotalWrites) or 0
ResourceManager.TotalConflicts = tonumber(ResourceManager.TotalConflicts) or 0
ResourceManager.Window = tonumber(ResourceManager.Window) or 0.18
ResourceManager.MaxConflicts = tonumber(ResourceManager.MaxConflicts) or 30
ResourceManager.Owners = ResourceManager.Owners or {}
function ResourceManager:Register(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string" or definition.id == "" then return false end
    local writes = {}
    if type(definition.writes) == "table" then
        for _, resource in ipairs(definition.writes) do if type(resource) == "string" then writes[resource] = true end end
    end
    self.Modules[definition.id] = { id = definition.id, writes = writes, priority = tonumber(definition.priority) or 0 }
    return true
end
function ResourceManager:RecordWrite(moduleId, resource)
    if type(moduleId) ~= "string" or type(resource) ~= "string" then return false end
    local module = self.Modules[moduleId]
    if not module or not module.writes[resource] then return false end
    local now = os.clock()
    self.TotalWrites = self.TotalWrites + 1
    local recent, kept = self.RecentWrites[resource] or {}, {}
    for _, event in ipairs(recent) do
        if now - event.time <= self.Window then
            kept[#kept + 1] = event
            if event.module ~= moduleId then
                local firstId, secondId = event.module, moduleId
                if firstId > secondId then firstId, secondId = secondId, firstId end
                local key = resource .. "|" .. firstId .. "|" .. secondId
                if now - (self.LastConflictAt[key] or 0) >= 0.5 then
                    self.LastConflictAt[key] = now
                    self.TotalConflicts = self.TotalConflicts + 1
                    self.Conflicts[#self.Conflicts + 1] = {
                        resource = resource, first = event.module, second = moduleId, time = now,
                        priorityFirst = self.Modules[event.module] and self.Modules[event.module].priority or 0,
                        prioritySecond = module.priority
                    }
                    while #self.Conflicts > self.MaxConflicts do table.remove(self.Conflicts, 1) end
                end
            end
        end
    end
    kept[#kept + 1] = { module = moduleId, time = now }
    self.RecentWrites[resource] = kept
    return true
end
function ResourceManager:GetStatus()
    local moduleCount, ownerCount = 0, 0
    for _ in pairs(self.Modules) do moduleCount = moduleCount + 1 end
    for _ in pairs(self.Owners) do ownerCount = ownerCount + 1 end
    return { mode = self.Mode, modules = moduleCount, owners = ownerCount,
        writes = self.TotalWrites, conflicts = self.TotalConflicts, latest = self.Conflicts[#self.Conflicts] }
end
TJ.ResourceManager = ResourceManager
_tjRMEnv.TAYJAY_RESOURCE_MANAGER = ResourceManager
