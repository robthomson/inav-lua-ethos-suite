--[[

 * Copyright (C) Inav Project
 *
 *
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 
 * Note.  Some icons have been sourced from https://www.flaticon.com/
 * 

]] --
--
-- background processing of msp traffic
--
local arg = {...}
local config = arg[1]

local msp = {}

msp.activeProtocol = nil
msp.onConnectChecksInit = true

local protocol = assert(inavsuite.compiler.loadfile("tasks/msp/protocols.lua"))()

local telemetryTypeChanged = false

msp.mspQueue = nil

-- set active protocol to use
msp.protocol = protocol.getProtocol()

-- preload all transport methods
msp.protocolTransports = {}
for i, v in pairs(protocol.getTransports()) do msp.protocolTransports[i] = assert(inavsuite.compiler.loadfile(v))() end

-- set active transport table to use
local transport = msp.protocolTransports[msp.protocol.mspProtocol]
msp.protocol.mspRead = transport.mspRead
msp.protocol.mspSend = transport.mspSend
msp.protocol.mspWrite = transport.mspWrite
msp.protocol.mspPoll = transport.mspPoll

msp.mspQueue = assert(inavsuite.compiler.loadfile("tasks/msp/mspQueue.lua"))()
msp.mspQueue.maxRetries = msp.protocol.maxRetries
msp.mspQueue.loopInterval = 0.01   -- process every 10ms (throttles CPU)
msp.mspQueue.copyOnAdd    = false  -- keep RAM/GC low (set true for strict immutability)
msp.mspQueue.timeout      = 2.0    -- per-message timeout (override if you want)

msp.mspHelper = assert(inavsuite.compiler.loadfile("tasks/msp/mspHelper.lua"))()
msp.api = assert(inavsuite.compiler.loadfile("tasks/msp/api.lua"))()
msp.common = assert(inavsuite.compiler.loadfile("tasks/msp/common.lua"))()

local delayDuration = 2  -- seconds
local delayStartTime = nil
local delayPending = false

function msp.wakeup()

    if inavsuite.session.telemetrySensor == nil then 
        --inavsuite.utils.log("No telemetry sensor configured", "info")
        return 
    end

    if not msp.sensor then
        msp.sensor = sport.getSensor({primId = 0x32})
        msp.sensor:module(inavsuite.session.telemetrySensor:module())
    end
    
    if not msp.sensorTlm then
        msp.sensorTlm = sport.getSensor()
        msp.sensorTlm:module(inavsuite.session.telemetrySensor:module())
    end

    if inavsuite.session.resetMSP and not delayPending then
        delayStartTime = os.clock()
        delayPending = true
        inavsuite.session.resetMSP = false  -- Reset immediately
        inavsuite.utils.log("Delaying msp wakeup for " .. delayDuration .. " seconds","info")
        return  -- Exit early; wait starts now
    end

    if delayPending then
        if os.clock() - delayStartTime >= delayDuration then
            inavsuite.utils.log("Delay complete; resuming msp wakeup","info")
            delayPending = false
        else
            inavsuite.tasks.msp.mspQueue:clear()
            return  -- Still waiting; do nothing
        end
    end

   msp.activeProtocol = inavsuite.session.telemetryType

    if telemetryTypeChanged == true then

        --inavsuite.utils.log("Switching protocol: " .. msp.activeProtocol)

        msp.protocol = protocol.getProtocol()

        -- set active transport table to use
        local transport = msp.protocolTransports[msp.protocol.mspProtocol]
        msp.protocol.mspRead = transport.mspRead
        msp.protocol.mspSend = transport.mspSend
        msp.protocol.mspWrite = transport.mspWrite
        msp.protocol.mspPoll = transport.mspPoll

        inavsuite.utils.session()
        msp.onConnectChecksInit = true
        telemetryTypeChanged = false
    end

    if inavsuite.session.telemetrySensor ~= nil and inavsuite.session.telemetryState == false then
        inavsuite.utils.session()
        msp.onConnectChecksInit = true
    end

    -- run the msp.checks

    local state

    if inavsuite.session.telemetrySensor then
        state = inavsuite.session.telemetryState
    else
        state = false
    end

    if state == true then
        
        msp.mspQueue:processQueue()

        -- checks that run on each connection to the fbl
        if msp.onConnectChecksInit == true then 
            if inavsuite.session.telemetrySensor then msp.sensor:module(inavsuite.session.telemetrySensor:module()) end
        end
    else
        msp.mspQueue:clear()
    end

end

function msp.setTelemetryTypeChanged()
    telemetryTypeChanged = true
end

function msp.reset()
    inavsuite.tasks.msp.mspQueue:clear()
    msp.sensor = nil
    msp.activeProtocol = nil
    msp.onConnectChecksInit = true
    delayStartTime = nil
    msp.sensorTlm = nil
    delayPending = false    
end

return msp
