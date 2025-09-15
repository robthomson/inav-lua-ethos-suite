--[[
 * Copyright (C) Rotorflight Project
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

local servos = {}

local mspCall1Made = false
local mspCall2Made = false

function servos.wakeup()
    -- quick exit if no apiVersion
    if inavsuite.session.apiVersion == nil then return end    


    if (inavsuite.session.servoCount == nil) and (mspCall1Made == false) then
        mspCall1Made = true
        local API = inavsuite.tasks.msp.api.load("STATUS")
        API.setCompleteHandler(function(self, buf)
            inavsuite.session.servoCount = API.readValue("servo_count")
            if inavsuite.session.servoCount then
                inavsuite.utils.log("Servo count: " .. inavsuite.session.servoCount, "info")
            end    
        end)
        API.setUUID("d7e0db36-ca3c-4e19-9a64-40e76c78329c")
        API.read()

    elseif (inavsuite.session.servoOverride == nil) and (mspCall2Made == false) then
        mspCall2Made = true
        local API = inavsuite.tasks.msp.api.load("SERVO_OVERRIDE")
        API.setCompleteHandler(function(self, buf)
            for i, v in pairs(API.data().parsed) do
                if v == 0 then
                    inavsuite.utils.log("Servo override: true (" .. i .. ")", "info")
                    inavsuite.session.servoOverride = true
                end
            end
            if inavsuite.session.servoOverride == nil then inavsuite.session.servoOverride = false end
        end)
        API.setUUID("b9617ec3-5e01-468e-a7d5-ec7460d277ef")
        API.read()
    end    

end

function servos.reset()
    inavsuite.session.servoCount = nil
    inavsuite.session.servoOverride = nil
    mspCall1Made = false
    mspCall2Made = false
end

function servos.isComplete()
    if inavsuite.session.servoCount ~= nil and inavsuite.session.servoOverride ~= nil then
        return true
    end
end

return servos