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

local clocksync = {}

local mspCallMade = false

function clocksync.wakeup()
    -- quick exit if no apiVersion
    if inavsuite.session.apiVersion == nil then return end    

    if inavsuite.session.clockSet == nil and mspCallMade == false then

        mspCallMade = true

        local API = inavsuite.tasks.msp.api.load("RTC", 1)
        API.setCompleteHandler(function(self, buf)
            inavsuite.session.clockSet = true
            inavsuite.utils.log("Sync clock: " .. os.date("%c"), "info")
        end)
        API.setUUID("eaeb0028-219b-4cec-9f57-3c7f74dd49ac")
        API.setValue("seconds", os.time())
        API.setValue("milliseconds", 0)
        API.write()
    end

end

function clocksync.reset()
    inavsuite.session.clockSet = nil
    mspCallMade = false
end

function clocksync.isComplete()
    if inavsuite.session.clockSet ~= nil then
        return true
    end
end

return clocksync