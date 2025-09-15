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

local craftname = {}

local mspCallMade = false

function craftname.wakeup()
    -- quick exit if no apiVersion
    if inavsuite.session.apiVersion == nil then return end    

    if inavsuite.session.mspBusy then return end

    if (inavsuite.session.craftName == nil) and (mspCallMade == false) then
        mspCallMade = true
        local API = inavsuite.tasks.msp.api.load("NAME")
        API.setCompleteHandler(function(self, buf)
            inavsuite.session.craftName = API.readValue("name")
            if inavsuite.preferences.general.syncname == true and model.name and inavsuite.session.craftName ~= nil then
                inavsuite.utils.log("Setting model name to: " .. inavsuite.session.craftName, "info")
                model.name(inavsuite.session.craftName)
                lcd.invalidate()
            end
            if inavsuite.session.craftName and inavsuite.session.craftName ~= "" then
                inavsuite.utils.log("Craft name: " .. inavsuite.session.craftName, "info")
            else
                inavsuite.session.craftName = model.name()    
            end
        end)
        API.setUUID("37163617-1486-4886-8b81-6a1dd6d7edd1")
        API.read()
    end     

end

function craftname.reset()
    inavsuite.session.craftName = nil
    mspCallMade = false
end

function craftname.isComplete()
    if inavsuite.session.craftName ~= nil then
        return true
    end
end

return craftname