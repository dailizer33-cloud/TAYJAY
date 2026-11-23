-- Keep player-WARP controls in sync after MONSTER takes movement ownership.
-- The ownership handoff stops WARP synchronously, but its original UI callback is
-- not invoked by that cleanup path. Observe the mode transition and refresh all
-- related controls once the handoff has completed.
task.spawn(function()
    local lastMonsterWarp = false
    while screenGui and screenGui.Parent do
        local monsterOn = states.MonsterWarp == true
        if monsterOn and not lastMonsterWarp then
            states.KillAura = false
            if type(syncButtonState) == "function" then
                syncButtonState("DNWarp", false)
                syncButtonState("AutoWarp", false)
            else
                states.DNWarp = false
                states.AutoWarp = false
            end
            if type(updateKaBtnDisplay) == "function" then
                updateKaBtnDisplay()
            end
        end
        lastMonsterWarp = monsterOn
        task.wait(0.05)
    end
end)
