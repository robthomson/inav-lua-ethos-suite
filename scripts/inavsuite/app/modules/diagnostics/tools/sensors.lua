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
local fields = {}
local labels = {}
local i18n = inavsuite.i18n.get
local enableWakeup = false

local w, h = lcd.getWindowSize()
local buttonW = 100
local buttonWs = buttonW - (buttonW * 20) / 100
local x = w - 15

local displayPos = {x = x - buttonW - buttonWs - 5 - buttonWs, y = inavsuite.app.radio.linePaddingTop, w = 100, h = inavsuite.app.radio.navbuttonHeight}

local invalidSensors = inavsuite.tasks.telemetry.validateSensors()

local repairSensors = false

local progressLoader
local progressLoaderCounter = 0
local doDiscoverNotify = false


local function sortSensorListByName(sensorList)
    table.sort(sensorList, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    return sensorList
end

local sensorList = sortSensorListByName(inavsuite.tasks.telemetry.listSensors())

local function openPage(pidx, title, script)
    enableWakeup = false
    inavsuite.app.triggers.closeProgressLoader = true

    form.clear()

    -- track page
    inavsuite.app.lastIdx   = pidx   -- was idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript= script

    inavsuite.app.ui.fieldHeader(inavsuite.i18n.get("app.modules.diagnostics.name")  .. " / " .. inavsuite.i18n.get("app.modules.validate_sensors.name"))

    -- fresh tables so lookups are never stale/nil
    inavsuite.app.formLineCnt = 0
    inavsuite.app.formFields  = {}
    inavsuite.app.formLines   = {}

    local posText = { x = x - 5 - buttonW - buttonWs, y = inavsuite.app.radio.linePaddingTop, w = 200, h = inavsuite.app.radio.navbuttonHeight }
    for i, v in ipairs(sensorList or {}) do
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        inavsuite.app.formLines[inavsuite.app.formLineCnt] = form.addLine(v.name)
        inavsuite.app.formFields[v.key] = form.addStaticText(inavsuite.app.formLines[inavsuite.app.formLineCnt], posText, "-")
    end

    enableWakeup = true
end

function sensorKeyExists(searchKey, sensorTable)
    if type(sensorTable) ~= "table" then return false end

    for _, sensor in pairs(sensorTable) do if sensor['key'] == searchKey then return true end end

    return false
end

local function postLoad(self)
    inavsuite.utils.log("postLoad","debug")
end

local function postRead(self)
    inavsuite.utils.log("postRead","debug")
end


local function rebootFC()

    local RAPI = inavsuite.tasks.msp.api.load("REBOOT")
    RAPI.setUUID("123e4567-e89b-12d3-a456-426614174000")
    RAPI.setCompleteHandler(function(self)
        inavsuite.utils.log("Rebooting FC","info")

        inavsuite.utils.onReboot()

    end)
    RAPI.write()
    
end

local function applySettings()
    local EAPI = inavsuite.tasks.msp.api.load("EEPROM_WRITE")
    EAPI.setUUID("550e8400-e29b-41d4-a716-446655440000")
    EAPI.setCompleteHandler(function(self)
        inavsuite.utils.log("Writing to EEPROM","info")
        rebootFC()
    end)
    EAPI.write()

end


local function runRepair(data)

    local sensorList = inavsuite.tasks.telemetry.listSensors()
    local newSensorList = {}

    -- Grab list of required sensors
    local count = 1
    for _, v in pairs(sensorList) do
        local sensor_id = v['set_telemetry_sensors']
        if sensor_id ~= nil and not newSensorList[sensor_id] then
            newSensorList[sensor_id] = true
            count = count + 1
        end    
    end   

    -- Include currently supplied sensors (excluding zeros)
    for i, v in pairs(data['parsed']) do
        if string.match(i, "^telem_sensor_slot_%d+$") and v ~= 0 then
            local sensor_id = v
            if sensor_id ~= nil and not newSensorList[sensor_id] then
                newSensorList[sensor_id] = true
                count = count + 1
            end    
        end    
    end       


    local WRITEAPI = inavsuite.tasks.msp.api.load("TELEMETRY_CONFIG")
    WRITEAPI.setUUID("123e4567-e89b-12d3-a456-426614174000")
    WRITEAPI.setCompleteHandler(function(self, buf)
        applySettings()
    end)

    local buffer = data['buffer']  -- Existing buffer
    local sensorIndex = 13  -- Start at byte 13 (1-based indexing)

    -- Convert newSensorList keys to an array (since Lua tables are not ordered)
    local sortedSensorIds = {}
    for sensor_id, _ in pairs(newSensorList) do
        table.insert(sortedSensorIds, sensor_id)
    end

    -- Sort sensor IDs to ensure consistency
    table.sort(sortedSensorIds)

    -- Insert new sensors into buffer
    for _, sensor_id in ipairs(sortedSensorIds) do
        if sensorIndex <= 52 then  -- 13 bytes + 40 sensor slots = 53 max (1-based)
            buffer[sensorIndex] = sensor_id
            sensorIndex = sensorIndex + 1
        else
            break  -- Stop if buffer limit is reached
        end
    end

    -- Fill remaining slots with zeros
    for i = sensorIndex, 52 do
        buffer[i] = 0
    end

    -- Send updated buffer
    WRITEAPI.write(buffer)

end


local function wakeup()

    -- prevent wakeup running until after initialised
    if enableWakeup == false then return end

    if doDiscoverNotify == true then

        doDiscoverNotify = false

        local buttons = {{
            label = inavsuite.i18n.get("app.btn_ok"),
            action = function()
                return true
            end
        }}
    
        if inavsuite.utils.ethosVersionAtLeast({1,6,3}) then
            inavsuite.utils.log("Starting discover sensors", "info")
            inavsuite.tasks.msp.sensorTlm:discover()
        else    
            form.openDialog({
                width = nil,
                title =  inavsuite.i18n.get("app.modules.validate_sensors.name"),
                message = inavsuite.i18n.get("app.modules.validate_sensors.msg_repair_fin"),
                buttons = buttons,
                wakeup = function()
                end,
                paint = function()
                end,
                options = TEXT_LEFT
            })
        end
    end


    -- check for updates
    invalidSensors = inavsuite.tasks.telemetry.validateSensors()

    for i, v in ipairs(sensorList) do
        -- Guard: field may not exist during the first few wakeups
        local field = inavsuite.app.formFields and inavsuite.app.formFields[v.key]
        if field then
            if sensorKeyExists(v.key, invalidSensors) then
                if v.mandatory == true then
                    field:value(inavsuite.i18n.get("app.modules.validate_sensors.invalid"))
                    field:color(ORANGE)
                else
                    field:value(inavsuite.i18n.get("app.modules.validate_sensors.invalid"))
                    field:color(RED)
                end
            else
                field:value(inavsuite.i18n.get("app.modules.validate_sensors.ok"))
                field:color(GREEN)
            end
        end
    end

  -- run process to repair all sensors
  if repairSensors == true then

        -- show the progress dialog
        progressLoader = form.openProgressDialog(inavsuite.i18n.get("app.msg_saving"), inavsuite.i18n.get("app.msg_saving_to_fbl"))
        progressLoader:closeAllowed(false)
        progressLoaderCounter = 0

        API = inavsuite.tasks.msp.api.load("TELEMETRY_CONFIG")
        API.setUUID("550e8400-e29b-41d4-a716-446655440000")
        API.setCompleteHandler(function(self, buf)
            local data = API.data()
            if data['parsed'] then
                runRepair(data)
            end
        end)
        API.read()
        repairSensors = false
    end  

    -- enable/disable the tool button
    if inavsuite.app.formNavigationFields['tool'] then
        if inavsuite.session and inavsuite.session.apiVersion and inavsuite.utils.apiVersionCompare("<", "12.08") then
            inavsuite.app.formNavigationFields['tool']:enable(false)
        else
            inavsuite.app.formNavigationFields['tool']:enable(true)
        end
    end

    if progressLoader then
        if progressLoaderCounter < 100 then
            progressLoaderCounter = progressLoaderCounter + 5
            progressLoader:value(progressLoaderCounter)
        else    
            progressLoader:close()    
            progressLoader = nil

            -- notify user to do a discover sensors
            doDiscoverNotify = true

        end    
    end    

end

local function onToolMenu(self)

    local buttons = {{
        label = inavsuite.i18n.get("app.btn_ok"),
        action = function()

            -- we push this to the background task to do its job
            repairSensors = true
            writePayload = nil
            return true
        end
    }, {
        label = inavsuite.i18n.get("app.btn_cancel"),
        action = function()
            return true
        end
    }}

    form.openDialog({
        width = nil,
        title =  inavsuite.i18n.get("app.modules.validate_sensors.name"),
        message = inavsuite.i18n.get("app.modules.validate_sensors.msg_repair"),
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()
        end,
        options = TEXT_LEFT
    })

end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.diagnostics.name"),
            "diagnostics/diagnostics.lua"
        )
        return true
    end
end


local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil,nil,true)
    inavsuite.app.ui.openPage(
        pageIdx,
        i18n("app.modules.diagnostics.name"),
        "diagnostics/diagnostics.lua"
    )
end

return {
    reboot = false,
    eepromWrite = false,
    minBytes = 0,
    wakeup = wakeup,
    refreshswitch = false,
    simulatorResponse = {},
    postLoad = postLoad,
    postRead = postRead,
    openPage = openPage,
    --onToolMenu = onToolMenu,
    onNavMenu = onNavMenu,
    event = event,
    navButtons = {
        menu = true,
        save = false,
        reload = false,
        tool = false,
        help = false
    },
    API = {},
}
