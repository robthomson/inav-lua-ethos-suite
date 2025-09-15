--[[
 * Copyright (C) Rotorflight Project
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
--]]

local tasks = {}
local tasksList = {}
local tasksLoaded = false

local telemetryTypeChanged = false

local TASK_TIMEOUT_SECONDS = 10


-- Debounce for telemetryTypeChanged -> avoid repeated resets on ELRS/S.Port flaps
local TYPE_CHANGE_DEBOUNCE = 1.0  -- seconds
local lastTypeChangeAt = 0
-- Base path and priority levels
local BASE_PATH = "tasks/onconnect/tasks/"
local PRIORITY_LEVELS = {"high", "medium", "low"}

-- Initialize or reset session flags
local function resetSessionFlags()
    inavsuite.session.onConnect = inavsuite.session.onConnect or {}
    for _, level in ipairs(PRIORITY_LEVELS) do
        inavsuite.session.onConnect[level] = false
    end
    -- Ensure isConnected resets until high priority completes
    inavsuite.session.isConnected = false
end

-- Discover task files in fixed priority order
function tasks.findTasks()
    if tasksLoaded then return end

    resetSessionFlags()

    for _, level in ipairs(PRIORITY_LEVELS) do
        local dirPath = BASE_PATH .. level .. "/"
        local files = system.listFiles(dirPath) or {}
        for _, file in ipairs(files) do
            if file:match("%.lua$") then
                local fullPath = dirPath .. file
                local name = level .. "/" .. file:gsub("%.lua$", "")
                local chunk, err = inavsuite.compiler.loadfile(fullPath)
                if not chunk then
                    inavsuite.utils.log("Error loading task " .. fullPath .. ": " .. err, "error")
                else
                    local module = assert(chunk())
                    if type(module) == "table" and type(module.wakeup) == "function" then
                        tasksList[name] = {
                            module = module,
                            priority = level,
                            initialized = false,
                            complete = false,
                            startTime = nil
                        }
                    else
                        inavsuite.utils.log("Invalid task file: " .. fullPath, "info")
                    end
                end
            end
        end
    end

    tasksLoaded = true
end

function tasks.resetAllTasks()
    for _, task in pairs(tasksList) do
        if type(task.module.reset) == "function" then task.module.reset() end
        task.initialized = false
        task.complete = false
        task.startTime = nil
    end

    resetSessionFlags()
    inavsuite.tasks.reset()
    inavsuite.session.resetMSPSensors = true
end

function tasks.wakeup()
    local telemetryActive = inavsuite.tasks.msp.onConnectChecksInit and inavsuite.session.telemetryState

    if telemetryTypeChanged then
        telemetryTypeChanged = false
        tasks.resetAllTasks()
        tasksLoaded = false
        return
    end

    if not telemetryActive then
        tasks.resetAllTasks()
        tasksLoaded = false
        return
    end

    if not tasksLoaded then
        tasks.findTasks()
    end

    -- Find the first priority level that isn't complete yet.
    local activeLevel = nil
    for _, level in ipairs(PRIORITY_LEVELS) do
        if not inavsuite.session.onConnect[level] then
            activeLevel = level
            break
        end
    end

    -- If no active level, everything is finished – nothing to do this cycle.
    if not activeLevel then
        return
    end

    local now = os.clock()

    -- Only run tasks from the active level.
    for name, task in pairs(tasksList) do
        if task.priority == activeLevel then
            if not task.initialized then
                task.initialized = true
                task.startTime = now
            end
            if not task.complete then
                inavsuite.utils.log("Waking up " .. name, "debug")
                task.module.wakeup()
                if task.module.isComplete and task.module.isComplete() then
                    task.complete = true
                    task.startTime = nil
                    inavsuite.utils.log("Completed " .. name, "debug")
                elseif task.startTime and (now - task.startTime) > TASK_TIMEOUT_SECONDS then
                    inavsuite.utils.log("Task '" .. name .. "' timed out.", "info")
                    tasks.resetAllTasks()
                    task.startTime = nil
                end
            end
        end
    end

    -- Check if the active level just finished; if so, set flags and return early.
    local levelDone = true
    for _, task in pairs(tasksList) do
        if task.priority == activeLevel and not task.complete then
            levelDone = false
            break
        end
    end

    if levelDone then
        inavsuite.session.onConnect[activeLevel] = true
        inavsuite.utils.log("All '" .. activeLevel .. "' tasks complete.", "info")

        if activeLevel == "high" then
            inavsuite.utils.playFileCommon("beep.wav")
            inavsuite.flightmode.current = "preflight"
            inavsuite.tasks.events.flightmode.reset()
            inavsuite.session.isConnectedHigh = true
            return
        elseif activeLevel == "medium" then
            inavsuite.session.isConnectedMedium = true
            return
        elseif activeLevel == "low" then
            inavsuite.session.isConnectedLow = true
            inavsuite.session.isConnected = true
            collectgarbage()
            return
        end
    end
end

function tasks.setTelemetryTypeChanged()
    telemetryTypeChanged = true
    lastTypeChangeAt = os.clock()
end


return tasks
