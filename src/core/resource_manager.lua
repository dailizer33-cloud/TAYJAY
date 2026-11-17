-- =========================================================
-- TAYJAY RESOURCE MANAGER V1 — MONITOR MODE (NON-BLOCKING)
-- Observes declared writes only. It never acquires, blocks, preempts,
-- or changes the behavior of a registered feature.
-- =========================================================
local ResourceManager = {
    Mode = "MONITOR",
    Modules = {},
    RecentWrites = {},
    LastConflictAt = {},
    Conflicts = {},
    TotalWrites = 0,
    TotalConflicts = 0,
    Window = 0.18,
    MaxConflicts = 30
}
function ResourceManager:Register(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string" then return false end
    local writes = {}
    for _, resource in ipairs(definition.writes or {}) do
        if type(resource) == "string" then writes[resource] = true end
    end
    self.Modules[definition.id] = { id = definition.id, writes = writes, priority = tonumber(definition.priority) or 0 }
    return true
end
function ResourceManager:RecordWrite(moduleId, resource)
    local module = self.Modules[moduleId]
    if not module or not module.writes[resource] then return end
    local now = os.clock()
    self.TotalWrites = self.TotalWrites + 1
    local recent = self.RecentWrites[resource] or {}
    local kept = {}
    for _, event in ipairs(recent) do
        if now - event.time <= self.Window then
            kept[#kept + 1] = event
            if event.module ~= moduleId then
                local firstId, secondId = event.module, moduleId
                if firstId > secondId then firstId, secondId = secondId, firstId end
                local conflictKey = resource .. "|" .. firstId .. "|" .. secondId
                if now - (self.LastConflictAt[conflictKey] or 0) >= 0.5 then
                    self.LastConflictAt[conflictKey] = now
                    self.TotalConflicts = self.TotalConflicts + 1
                    local conflict = {
                        resource = resource, first = event.module, second = moduleId,
                        time = now, priorityFirst = self.Modules[event.module] and self.Modules[event.module].priority or 0,
                        prioritySecond = module.priority
                    }
                    self.Conflicts[#self.Conflicts + 1] = conflict
                    while #self.Conflicts > self.MaxConflicts do table.remove(self.Conflicts, 1) end
                end
            end
        end
    end
    kept[#kept + 1] = { module = moduleId, time = now }
    self.RecentWrites[resource] = kept
end
function ResourceManager:GetStatus()
    return {
        mode = self.Mode, modules = #((function()
            local ids = {}; for id in pairs(self.Modules) do ids[#ids + 1] = id end; return ids
        end)()),
        writes = self.TotalWrites, conflicts = self.TotalConflicts,
        latest = self.Conflicts[#self.Conflicts]
    }
end
_G.TAYJAY_RESOURCE_MANAGER = ResourceManager

