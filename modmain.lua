local function SleepingAdvancesTime(inst, sleeper)
    if (not GLOBAL.TheWorld.ismastersim) then
        return
    end

    inst:DoTaskInTime(5, function()
        local Time          = 0
        local PhaseTimeLeft = (1 - GLOBAL.TheWorld.state.timeinphase)
        local Length_Dusk   = (TUNING.SEG_TIME * TUNING.DUSK_SEGS_DEFAULT)
        local Length_Night  = (TUNING.SEG_TIME * TUNING.NIGHT_SEGS_DEFAULT)

        if (GLOBAL.TheWorld.state.phase == "dusk") then
            Time = (Length_Dusk * PhaseTimeLeft)
            Time = Time + (Length_Night * PhaseTimeLeft)

        elseif (GLOBAL.TheWorld.state.phase == "night") then
            Time = (Length_Night * PhaseTimeLeft)
        end

        local MinStatPercentage = 0
        local MaxStat           = 0
        local TickRate          = 0

        if (sleeper.components.health:GetPercentWithPenalty() < sleeper.components.sanity:GetPercentWithPenalty()) then
            MinStatPercentage = sleeper.components.health:GetPercentWithPenalty()
            MaxStat = sleeper.components.health:GetMaxWithPenalty()
            TickRate = TUNING.SLEEP_HEALTH_PER_TICK
        else
            MinStatPercentage = sleeper.components.sanity:GetPercentWithPenalty()
            MaxStat = sleeper.components.sanity:GetMaxWithPenalty()
            TickRate = TUNING.SLEEP_SANITY_PER_TICK
        end

        local TicksNeeded = ((MaxStat * (1 - MinStatPercentage)) * TickRate)

        local TicksAvailable = (sleeper.components.hunger.current / -TUNING.SLEEP_HUNGER_PER_TICK)

        if (not GLOBAL.TheWorld:HasTag("cave")) then
            if (Time > TicksAvailable) then
                Time = TicksAvailable
            end
            if (Time > TicksNeeded) then
                Time = TicksNeeded
            end
        else
            if (TicksAvailable > TicksNeeded) then
                TicksAvailable = TicksNeeded
            end

            Time = TicksAvailable
        end

        if sleeper.components.sanity then
            sleeper.components.sanity:DoDelta(Time * TUNING.SLEEP_SANITY_PER_TICK)
        end
        if sleeper.components.hunger then
            sleeper.components.hunger:DoDelta(Time * TUNING.SLEEP_HUNGER_PER_TICK, false, true)
        end
        if sleeper.components.health then
            sleeper.components.health:DoDelta(Time * TUNING.SLEEP_HEALTH_PER_TICK * 2, false, "tent", true)
        end
        if sleeper.components.temperature then
            local Temperature = (Time * TUNING.SLEEP_TEMP_PER_TICK)

            if ((sleeper.components.temperature:GetCurrent() + Temperature) > TUNING.SLEEP_TARGET_TEMP_TENT) then
                Temperature = TUNING.SLEEP_TARGET_TEMP_TENT
            end

            sleeper.components.temperature:SetTemperature(Temperature)
        end
        if sleeper.components.moisture then
            sleeper.components.moisture:DoDelta(Time * TUNING.SLEEP_WETNESS_PER_TICK)
        end

        if (inst.components.finiteuses ~= nil) then
            inst.components.finiteuses:Use()
        end

        GLOBAL.TheWorld:PushEvent("ms_nextcycle")

        sleeper.sg:GoToState("wakeup")
    end)
end


local function ApplySleepLogic(Prefab)
    if Prefab.components.sleepingbag ~= nil then
        Prefab.components.sleepingbag.onsleep = SleepingAdvancesTime
    end
end

AddPrefabPostInit("tent", ApplySleepLogic)
AddPrefabPostInit("portabletent", ApplySleepLogic)
AddPrefabPostInit("bedroll_straw", ApplySleepLogic)
--Seems to be an error where it uses 66% of the furry bedroll in one use, so disabled for now.
--AddPrefabPostInit("bedroll_furry", ApplySleepLogic)