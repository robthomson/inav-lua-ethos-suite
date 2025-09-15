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

local tailmode = {}

local mspCallMade = false

function tailmode.wakeup()
    -- quick exit if no apiVersion
    if inavsuite.session.apiVersion == nil then return end    

    if (inavsuite.session.tailMode == nil or inavsuite.session.swashMode == nil)  and mspCallMade == false then
        mspCallMade = true
        local API = inavsuite.tasks.msp.api.load("MIXER_CONFIG")
        API.setCompleteHandler(function(self, buf)
            inavsuite.session.tailMode = API.readValue("tail_rotor_mode")
            inavsuite.session.swashMode = API.readValue("swash_type")
            if inavsuite.session.tailMode and inavsuite.session.swashMode then
                inavsuite.utils.log("Tail mode: " .. inavsuite.session.tailMode, "info")
                inavsuite.utils.log("Swash mode: " .. inavsuite.session.swashMode, "info")
            end
        end)
        API.setUUID("fbccd634-c9b7-4b48-8c02-08ef560dc515")
        API.read()  
    end

end

function tailmode.reset()
    inavsuite.session.tailMode = nil
    inavsuite.session.swashMode = nil
    mspCallMade = false
end

function tailmode.isComplete()
    if inavsuite.session.tailMode ~= nil and inavsuite.session.swashMode ~= nil then
        return true
    end
end

return tailmode