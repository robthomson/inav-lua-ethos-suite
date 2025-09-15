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

local governor = {}

local mspCallMade = false

function governor.wakeup()
    -- quick exit if no apiVersion
    if inavsuite.session.apiVersion == nil then return end    

    if (inavsuite.session.governorMode == nil and mspCallMade == false) then
        mspCallMade = true
        local API = inavsuite.tasks.msp.api.load("GOVERNOR_CONFIG")
        API.setCompleteHandler(function(self, buf)
            local governorMode = API.readValue("gov_mode")
            if governorMode then
                inavsuite.utils.log("Governor mode: " .. governorMode, "info")
            end
            inavsuite.session.governorMode = governorMode
        end)
        API.setUUID("e2a1c5b3-7f4a-4c8e-9d2a-3b6f8e2d9a1c")
        API.read()
    end        
end

function governor.reset()
    inavsuite.session.governorMode = nil
    mspCallMade = false
end

function governor.isComplete()
    if inavsuite.session.governorMode ~= nil then
        return true
    end
end

return governor