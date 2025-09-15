-- create 16 servos in disabled state
local SBUS_FUNCTIONMASK = 262144
local triggerOverRide = false
local triggerOverRideAll = false
local lastServoCountTime = os.clock()
local enableWakeup = false
local wakeupScheduler = os.clock()
local validSerialConfig = false
local i18n = inavsuite.i18n.get
local function openPage(pidx, title, script)


    inavsuite.tasks.msp.protocol.mspIntervalOveride = nil

    inavsuite.app.triggers.isReady = false
    inavsuite.app.uiState = inavsuite.app.uiStatus.pages

    form.clear()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    -- size of buttons
    if inavsuite.preferences.general.iconsize == nil or inavsuite.preferences.general.iconsize == "" then
        inavsuite.preferences.general.iconsize = 1
    else
        inavsuite.preferences.general.iconsize = tonumber(inavsuite.preferences.general.iconsize)
    end

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = inavsuite.app.radio.buttonPadding

    local sc
    local panel

    buttonW = 100
    local x = windowWidth - buttonW - 10

    inavsuite.app.ui.fieldHeader(i18n("app.modules.sbusout.title") .. "")

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    -- TEXT ICONS
    if inavsuite.preferences.general.iconsize == 0 then
        padding = inavsuite.app.radio.buttonPaddingSmall
        buttonW = (inavsuite.app.lcdWidth - padding) / inavsuite.app.radio.buttonsPerRow - padding
        buttonH = inavsuite.app.radio.navbuttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if inavsuite.preferences.general.iconsize == 1 then

        padding = inavsuite.app.radio.buttonPaddingSmall
        buttonW = inavsuite.app.radio.buttonWidthSmall
        buttonH = inavsuite.app.radio.buttonHeightSmall
        numPerRow = inavsuite.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if inavsuite.preferences.general.iconsize == 2 then

        padding = inavsuite.app.radio.buttonPadding
        buttonW = inavsuite.app.radio.buttonWidth
        buttonH = inavsuite.app.radio.buttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end

    local lc = 0
    local bx = 0

    if inavsuite.app.gfx_buttons["sbuschannel"] == nil then inavsuite.app.gfx_buttons["sbuschannel"] = {} end
    if inavsuite.preferences.menulastselected["sbuschannel"] == nil then inavsuite.preferences.menulastselected["sbuschannel"] = 0 end
    if inavsuite.currentSbusServoIndex == nil then inavsuite.currentSbusServoIndex = 0 end

    for pidx = 0, 15 do

        if lc == 0 then
            if inavsuite.preferences.general.iconsize == 0 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
            if inavsuite.preferences.general.iconsize == 1 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
            if inavsuite.preferences.general.iconsize == 2 then y = form.height() + inavsuite.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if inavsuite.preferences.general.iconsize ~= 0 then
            if inavsuite.app.gfx_buttons["sbuschannel"][pidx] == nil then inavsuite.app.gfx_buttons["sbuschannel"][pidx] = lcd.loadMask("app/modules/sbusout/gfx/ch" .. tostring(pidx + 1) .. ".png") end
        else
            inavsuite.app.gfx_buttons["sbuschannel"][pidx] = nil
        end

        inavsuite.app.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = i18n("app.modules.sbusout.channel_prefix") .. "" .. tostring(pidx + 1),
            icon = inavsuite.app.gfx_buttons["sbuschannel"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                inavsuite.preferences.menulastselected["sbuschannel"] = pidx
                inavsuite.currentSbusServoIndex = pidx
                inavsuite.app.ui.progressDisplay()
                inavsuite.app.ui.openPage(pidx, i18n("app.modules.sbusout.channel_page") .. "" .. tostring(inavsuite.currentSbusServoIndex + 1), "sbusout/sbusout_tool.lua")
            end
        })

        inavsuite.app.formFields[pidx]:enable(false)

        lc = lc + 1
        if lc == numPerRow then lc = 0 end

    end

    inavsuite.app.triggers.closeProgressLoader = true
    inavsuite.app.triggers.closeProgressLoaderNoisProcessed = true

    enableWakeup = true
    collectgarbage()
    return
end

local function processSerialConfig(data)

    for i, v in ipairs(data) do if v.functionMask == SBUS_FUNCTIONMASK then validSerialConfig = true end end

end

local function getSerialConfig()
    local message = {
        command = 54,
        processReply = function(self, buf)
            local data = {}

            buf.offset = 1
            for i = 1, 6 do
                data[i] = {}
                data[i].identifier = inavsuite.tasks.msp.mspHelper.readU8(buf)
                data[i].functionMask = inavsuite.tasks.msp.mspHelper.readU32(buf)
                data[i].msp_baudrateIndex = inavsuite.tasks.msp.mspHelper.readU8(buf)
                data[i].gps_baudrateIndex = inavsuite.tasks.msp.mspHelper.readU8(buf)
                data[i].telemetry_baudrateIndex = inavsuite.tasks.msp.mspHelper.readU8(buf)
                data[i].blackbox_baudrateIndex = inavsuite.tasks.msp.mspHelper.readU8(buf)
            end

            processSerialConfig(data)
        end,
        simulatorResponse = {20, 1, 0, 0, 0, 5, 4, 0, 5, 0, 0, 0, 4, 0, 5, 4, 0, 5, 1, 0, 0, 4, 0, 5, 4, 0, 5, 2, 0, 0, 0, 0, 5, 4, 0, 5, 3, 0, 0, 0, 0, 5, 4, 0, 5, 4, 64, 0, 0, 0, 5, 4, 0, 5}
    }
    inavsuite.tasks.msp.mspQueue:add(message)
end


local function wakeup()

    if enableWakeup == true and validSerialConfig == false then

        local now = os.clock()
        if (now - wakeupScheduler) >= 0.5 then
            wakeupScheduler = now

            getSerialConfig()

        end
    elseif enableWakeup == true and validSerialConfig == true then
        for pidx = 0, 15 do
            inavsuite.app.formFields[pidx]:enable(true)
            if inavsuite.preferences.menulastselected["sbuschannel"] == inavsuite.currentSbusServoIndex then inavsuite.app.formFields[inavsuite.currentSbusServoIndex]:focus() end
        end
        -- close the progressDisplay
    end

end

-- not changing to api for this module due to the unusual read/write scenario.
-- its not worth the effort
return {
    title = "Sbus Out",
    openPage = openPage,
    wakeup = wakeup,
    navButtons = {
        menu = true,
        save = false,
        reload = false,
        tool = false,
        help = true
    },
    API = {},
}
