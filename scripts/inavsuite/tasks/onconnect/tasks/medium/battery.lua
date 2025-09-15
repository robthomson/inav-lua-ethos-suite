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

local battery = {}

local mspCallMade = false

function battery.wakeup()
    -- quick exit if no apiVersion
    if inavsuite.session.apiVersion == nil then return end    

    if (inavsuite.session.batteryConfig == nil) and mspCallMade == false then
        mspCallMade = true

        local API = inavsuite.tasks.msp.api.load("BATTERY_CONFIG")
        API.setCompleteHandler(function(self, buf)
            local batteryCapacity = API.readValue("batteryCapacity")
            local batteryCellCount = API.readValue("batteryCellCount")
            local vbatwarningcellvoltage = API.readValue("vbatwarningcellvoltage")/100
            local vbatmincellvoltage = API.readValue("vbatmincellvoltage")/100
            local vbatmaxcellvoltage = API.readValue("vbatmaxcellvoltage")/100
            local vbatfullcellvoltage = API.readValue("vbatfullcellvoltage")/100
            local lvcPercentage = API.readValue("lvcPercentage")
            local consumptionWarningPercentage = API.readValue("consumptionWarningPercentage")

            inavsuite.session.batteryConfig = {}
            inavsuite.session.batteryConfig.batteryCapacity = batteryCapacity
            inavsuite.session.batteryConfig.batteryCellCount = batteryCellCount
            inavsuite.session.batteryConfig.vbatwarningcellvoltage = vbatwarningcellvoltage
            inavsuite.session.batteryConfig.vbatmincellvoltage = vbatmincellvoltage
            inavsuite.session.batteryConfig.vbatmaxcellvoltage = vbatmaxcellvoltage
            inavsuite.session.batteryConfig.vbatfullcellvoltage = vbatfullcellvoltage
            inavsuite.session.batteryConfig.lvcPercentage = lvcPercentage
            inavsuite.session.batteryConfig.consumptionWarningPercentage = consumptionWarningPercentage
            -- we also get a volage scale factor stored in this table - but its in pilot config

            inavsuite.utils.log("Capacity: " .. batteryCapacity .. "mAh","info")
            inavsuite.utils.log("Cell Count: " .. batteryCellCount,"info")
            inavsuite.utils.log("Warning Voltage: " .. vbatwarningcellvoltage .. "V","info")
            inavsuite.utils.log("Min Voltage: " .. vbatmincellvoltage .. "V","info")
            inavsuite.utils.log("Max Voltage: " .. vbatmaxcellvoltage .. "V","info")
            inavsuite.utils.log("Full Cell Voltage: " .. vbatfullcellvoltage .. "V", "info")
            inavsuite.utils.log("LVC Percentage: " .. lvcPercentage .. "%","info")
            inavsuite.utils.log("Consumption Warning Percentage: " .. consumptionWarningPercentage .. "%","info")
            inavsuite.utils.log("Battery Config Complete","info")
        end)
        API.setUUID("a3f9c2b4-5d7e-4e8a-9c3b-2f6d8e7a1b2d")
        API.read()
    end    

end

function battery.reset()
    inavsuite.session.batteryConfig = nil
    mspCallMade = false
end

function battery.isComplete()
    if inavsuite.session.batteryConfig ~= nil then
        return true
    end
end

return battery