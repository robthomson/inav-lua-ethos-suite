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
local fcStatus = {}
local dataflashSummary = {}
local wakeupScheduler = os.clock()
local status = {}
local summary = {}
local triggerEraseDataFlash = false
local enableWakeup = false

local displayType = 0
local disableType = false

local w, h = lcd.getWindowSize()
local buttonW = 100
local buttonWs = buttonW - (buttonW * 20) / 100
local x = w - 15

local displayPos = {x = x - buttonW - buttonWs - 5 - buttonWs, y = inavsuite.app.radio.linePaddingTop, w = 200, h = inavsuite.app.radio.navbuttonHeight}


local apidata = {
    api = {
        [1] = nil,
    },
    formdata = {
        labels = {
        },
        fields = {
            {t = "@i18n(app.modules.fblstatus.fbl_date)@", value = "-", type = displayType, disable = disableType, position = displayPos},
            {t = "@i18n(app.modules.fblstatus.fbl_time)@", value = "-", type = displayType, disable = disableType, position = displayPos},
            {t = "@i18n(app.modules.fblstatus.arming_flags)@", value = "-", type = displayType, disable = disableType, position = displayPos},
            {t = "@i18n(app.modules.fblstatus.dataflash_free_space)@", value = "-", type = displayType, disable = disableType, position = displayPos},
            {t = "@i18n(app.modules.fblstatus.real_time_load)@", value = "-", type = displayType, disable = disableType, position = displayPos},
            {t = "@i18n(app.modules.fblstatus.cpu_load)@", value = "-", type = displayType, disable = disableType, position = displayPos}
        }
    }                 
}


local function getSimulatorTimeResponse()
    local t = os.date("*t")  -- get local time
    local millis = math.floor((os.clock() % 1) * 1000)

    local year = t.year
    local month = t.month
    local day = t.day
    local hour = t.hour
    local min = t.min
    local sec = t.sec

    -- encode into byte array (little-endian)
    local bytes = {
        year & 0xFF,         -- year LSB
        (year >> 8) & 0xFF,  -- year MSB
        month,
        day,
        hour,
        min,
        sec,
        millis & 0xFF,       -- millis LSB
        (millis >> 8) & 0xFF -- millis MSB
    }

    return bytes
end

local function getFblTime()
    local message = {
        command = 247, -- MSP_STATUS
        processReply = function(self, buf)

            buf.offset = 1
            status.fblYear = inavsuite.tasks.msp.mspHelper.readU16(buf)
            buf.offset = 3
            status.fblMonth = inavsuite.tasks.msp.mspHelper.readU8(buf)
            buf.offset = 4
            status.fblDay = inavsuite.tasks.msp.mspHelper.readU8(buf)
            buf.offset = 5
            status.fblHour = inavsuite.tasks.msp.mspHelper.readU8(buf)
            buf.offset = 6
            status.fblMinute = inavsuite.tasks.msp.mspHelper.readU8(buf)
            buf.offset = 7
            status.fblSecond = inavsuite.tasks.msp.mspHelper.readU8(buf)
            buf.offset = 8
            status.fblMillis = inavsuite.tasks.msp.mspHelper.readU16(buf)

        end,
        simulatorResponse = getSimulatorTimeResponse()
    }

    inavsuite.tasks.msp.mspQueue:add(message)
end

local function getStatus()
    local message = {
        command = 101, -- MSP_STATUS
        processReply = function(self, buf)

            buf.offset = 12
            status.realTimeLoad = inavsuite.tasks.msp.mspHelper.readU16(buf)
            status.cpuLoad = inavsuite.tasks.msp.mspHelper.readU16(buf)
            buf.offset = 18
            status.armingDisableFlags = inavsuite.tasks.msp.mspHelper.readU32(buf)
            buf.offset = 24
            status.profile = inavsuite.tasks.msp.mspHelper.readU8(buf)
            buf.offset = 26
            status.rateProfile = inavsuite.tasks.msp.mspHelper.readU8(buf)


        end,
        simulatorResponse = {240, 1, 124, 0, 35, 0, 0, 0, 0, 0, 0, 224, 1, 10, 1, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 1, 4, 1}
    }

    inavsuite.tasks.msp.mspQueue:add(message)
end

local function getDataflashSummary()
    local message = {
        command = 70, -- MSP_DATAFLASH_SUMMARY
        processReply = function(self, buf)

            local flags = inavsuite.tasks.msp.mspHelper.readU8(buf)
            summary.ready = (flags & 1) ~= 0
            summary.supported = (flags & 2) ~= 0
            summary.sectors = inavsuite.tasks.msp.mspHelper.readU32(buf)
            summary.totalSize = inavsuite.tasks.msp.mspHelper.readU32(buf)
            summary.usedSize = inavsuite.tasks.msp.mspHelper.readU32(buf)

        end,
        simulatorResponse = {3, 1, 0, 0, 0, 0, 4, 0, 0, 0, 3, 0, 0}
    }
    inavsuite.tasks.msp.mspQueue:add(message)
end

local function eraseDataflash()
    local message = {
        command = 72, -- MSP_DATAFLASH_ERASE
        processReply = function(self, buf)

            summary = {}

            -- blank out vars so that we actually are aware that it updated
            inavsuite.app.formFields[1]:value("")
            inavsuite.app.formFields[2]:value("")
            inavsuite.app.formFields[3]:value("")
            inavsuite.app.formFields[4]:value("")
            inavsuite.app.formFields[5]:value("")
            inavsuite.app.formFields[6]:value("")
        end,
        simulatorResponse = {}
    }
    inavsuite.tasks.msp.mspQueue:add(message)
end

local function postLoad(self)

    getStatus()
    getDataflashSummary()
    getFblTime()
    inavsuite.app.triggers.isReady = true
    enableWakeup = true

    inavsuite.app.triggers.closeProgressLoader = true
end

local function postRead(self)
    inavsuite.utils.log("postRead","debug")
end

local function getFreeDataflashSpace()
    if not summary.supported then return "@i18n(app.modules.fblstatus.unsupported)@" end
    local freeSpace = summary.totalSize - summary.usedSize
    return string.format("%.1f " .. "@i18n(app.modules.fblstatus.megabyte)@", freeSpace / (1024 * 1024))
end

local function wakeup()

    -- prevent wakeup running until after initialised
    if enableWakeup == false then return end

    if triggerEraseDataFlash == true then
        inavsuite.app.audio.playEraseFlash = true
        triggerEraseDataFlash = false

        inavsuite.app.ui.progressDisplay("@i18n(app.modules.fblstatus.erasing)@", "@i18n(app.modules.fblstatus.erasing_dataflash)@")
        inavsuite.app.Page.eraseDataflash()
        inavsuite.app.triggers.isReady = true
    end

    if triggerEraseDataFlash == false then
        local now = os.clock()
        if (now - wakeupScheduler) >= 2 then
            wakeupScheduler = now
            firstRun = false
            if inavsuite.tasks.msp.mspQueue:isProcessed() then

                getStatus()
                getDataflashSummary()
                getFblTime()

                if status.fblYear ~= nil and status.fblMonth ~= nil and status.fblDay ~= nil then
                    local value = string.format("%04d-%02d-%02d", status.fblYear, status.fblMonth, status.fblDay)
                    inavsuite.app.formFields[1]:value(value)
                end

                if status.fblHour ~= nil and status.fblMinute ~= nil and status.fblSecond ~= nil then
                    local value = string.format("%02d:%02d:%02d", status.fblHour, status.fblMinute, status.fblSecond)
                    inavsuite.app.formFields[2]:value(value)
                end

                if status.armingDisableFlags ~= nil then
                    local value = inavsuite.utils.armingDisableFlagsToString(status.armingDisableFlags)
                    inavsuite.app.formFields[3]:value(value)
                end

                if summary.supported == true then
                    local value = getFreeDataflashSpace()
                    inavsuite.app.formFields[4]:value(value)
                end

                if status.realTimeLoad ~= nil then
                    local value = math.floor(status.realTimeLoad / 10)
                    inavsuite.app.formFields[5]:value(tostring(value) .. "%")
                    if value >= 60 then inavsuite.app.formFields[4]:color(RED) end
                end
                if status.cpuLoad ~= nil then
                    local value = status.cpuLoad / 10
                    inavsuite.app.formFields[6]:value(tostring(value) .. "%")
                    if value >= 60 then inavsuite.app.formFields[4]:color(RED) end
                end

            end
        end
        if (now - wakeupScheduler) >= 1 then
            inavsuite.app.triggers.closeProgressLoader = true
        end
    end

end

local function onToolMenu(self)

    local buttons = {{
        label = "@i18n(app.btn_ok_long)@",
        action = function()

            -- we cant launch the loader here to se rely on the modules
            -- wakup function to do this
            triggerEraseDataFlash = true
            return true
        end
    }, {
        label = "@i18n(app.btn_cancel)@",
        action = function()
            return true
        end
    }}
    local message
    local title

    title = "@i18n(app.modules.fblstatus.erase)@"
    message = "@i18n(app.modules.fblstatus.erase_prompt)@"

    form.openDialog({
        width = nil,
        title = title,
        message = message,
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
            "@i18n(app.modules.diagnostics.name)@",
            "diagnostics/diagnostics.lua"
        )
        return true
    end
end


local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil,nil,true)
    inavsuite.app.ui.openPage(
        pageIdx,
        "@i18n(app.modules.diagnostics.name)@",
        "diagnostics/diagnostics.lua"
    )
end

return {
    apidata = apidata,
    reboot = false,
    eepromWrite = false,
    minBytes = 0,
    wakeup = wakeup,
    refreshswitch = false,
    simulatorResponse = {},
    postLoad = postLoad,
    postRead = postRead,
    eraseDataflash = eraseDataflash,
    onToolMenu = onToolMenu,
    onNavMenu = onNavMenu,
    event = event,
    navButtons = {
        menu = true,
        save = false,
        reload = false,
        tool = true,
        help = false
    },
    API = {},
}
