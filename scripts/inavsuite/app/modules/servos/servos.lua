-- create 16 servos in disabled state
local servoTable = {}
servoTable = {}
servoTable['sections'] = {}

local triggerOverRide = false
local triggerOverRideAll = false
local lastServoCountTime = os.clock()
local i18n = inavsuite.i18n.get
local function buildServoTable()

    for i = 1, inavsuite.session.servoCount do
        servoTable[i] = {}
        servoTable[i] = {}
        servoTable[i]['title'] = i18n("app.modules.servos.servo_prefix") .. i
        servoTable[i]['image'] = "servo" .. i .. ".png"
        servoTable[i]['disabled'] = true
    end

    for i = 1, inavsuite.session.servoCount do
        -- enable actual number of servos
        servoTable[i]['disabled'] = false

        if inavsuite.session.swashMode == 0 then
            -- we do nothing as we cannot determine any servo names
        elseif inavsuite.session.swashMode == 1 then
            -- servo mode is direct - only servo for sure we know name of is tail
            if inavsuite.session.tailMode == 0 then
                servoTable[4]['title'] = i18n("app.modules.servos.tail")
                servoTable[4]['image'] = "tail.png"
                servoTable[4]['section'] = 1
            end
        elseif inavsuite.session.swashMode == 2 or inavsuite.session.swashMode == 3 or inavsuite.session.swashMode == 4 then
            -- servo mode is cppm - 
            servoTable[1]['title'] = i18n("app.modules.servos.cyc_pitch")
            servoTable[1]['image'] = "cpitch.png"

            servoTable[2]['title'] = i18n("app.modules.servos.cyc_left")
            servoTable[2]['image'] = "cleft.png"

            servoTable[3]['title'] = i18n("app.modules.servos.cyc_right")
            servoTable[3]['image'] = "cright.png"

            if inavsuite.session.tailMode == 0 then
                -- this is because when swiching models this may or may not have
                -- been created.
                if servoTable[4] == nil then servoTable[4] = {} end
                servoTable[4]['title'] = i18n("app.modules.servos.tail")
                servoTable[4]['image'] = "tail.png"
            else
                -- servoTable[4]['disabled'] = true
            end
        elseif inavsuite.session.swashMode == 5 or inavsuite.session.swashMode == 6 then
            -- servo mode is fpm 90
            -- servoTable[3]['disabled'] = true 
            if inavsuite.session.tailMode == 0 then
                servoTable[4]['title'] = i18n("app.modules.servos.tail")
                servoTable[4]['image'] = "tail.png"
            else
                -- servoTable[4]['disabled'] = true                
            end
        end
    end
end

local function swashMixerType()
    local txt
    if inavsuite.session.swashMode == 0 then
        txt = "NONE"
    elseif inavsuite.session.swashMode == 1 then
        txt = "DIRECT"
    elseif inavsuite.session.swashMode == 2 then
        txt = "CPPM 120°"
    elseif inavsuite.session.swashMode == 3 then
        txt = "CPPM 135°"
    elseif inavsuite.session.swashMode == 4 then
        txt = "CPPM 140°"
    elseif inavsuite.session.swashMode == 5 then
        txt = "FPPM 90° L"
    elseif inavsuite.session.swashMode == 6 then
        txt = "FPPM 90° R"
    else
        txt = "UNKNOWN"
    end

    return txt
end

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

    inavsuite.app.ui.fieldHeader(i18n("app.modules.servos.name"))

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

    if inavsuite.app.gfx_buttons["servos"] == nil then inavsuite.app.gfx_buttons["servos"] = {} end
    if inavsuite.preferences.menulastselected["servos"] == nil then inavsuite.preferences.menulastselected["servos"] = 1 end

    if inavsuite.app.gfx_buttons["servos"] == nil then inavsuite.app.gfx_buttons["servos"] = {} end
    if inavsuite.preferences.menulastselected["servos"] == nil then inavsuite.preferences.menulastselected["servos"] = 1 end

    for pidx, pvalue in ipairs(servoTable) do

        if pvalue.disabled ~= true then

            if pvalue.section == "swash" and lc == 0 then
                local headerLine = form.addLine("")
                local headerLineText = form.addStaticText(headerLine, {x = 0, y = inavsuite.app.radio.linePaddingTop, w = inavsuite.app.lcdWidth, h = inavsuite.app.radio.navbuttonHeight}, headerLineText())
            end

            if pvalue.section == "tail" then
                local headerLine = form.addLine("")
                local headerLineText = form.addStaticText(headerLine, {x = 0, y = inavsuite.app.radio.linePaddingTop, w = inavsuite.app.lcdWidth, h = inavsuite.app.radio.navbuttonHeight}, i18n("app.modules.servos.tail"))
            end

            if pvalue.section == "other" then
                local headerLine = form.addLine("")
                local headerLineText = form.addStaticText(headerLine, {x = 0, y = inavsuite.app.radio.linePaddingTop, w = inavsuite.app.lcdWidth, h = inavsuite.app.radio.navbuttonHeight}, i18n("app.modules.servos.tail"))
            end

            if lc == 0 then
                if inavsuite.preferences.general.iconsize == 0 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
                if inavsuite.preferences.general.iconsize == 1 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
                if inavsuite.preferences.general.iconsize == 2 then y = form.height() + inavsuite.app.radio.buttonPadding end
            end

            if lc >= 0 then bx = (buttonW + padding) * lc end

            if inavsuite.preferences.general.iconsize ~= 0 then
                if inavsuite.app.gfx_buttons["servos"][pidx] == nil then inavsuite.app.gfx_buttons["servos"][pidx] = lcd.loadMask("app/modules/servos/gfx/" .. pvalue.image) end
            else
                inavsuite.app.gfx_buttons["servos"][pidx] = nil
            end

            inavsuite.app.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = pvalue.title,
                icon = inavsuite.app.gfx_buttons["servos"][pidx],
                options = FONT_S,
                paint = function()
                end,
                press = function()
                    inavsuite.preferences.menulastselected["servos"] = pidx
                    inavsuite.currentServoIndex = pidx
                    inavsuite.app.ui.progressDisplay()
                    inavsuite.app.ui.openPage(pidx, pvalue.title, "servos/servos_tool.lua", servoTable)
                end
            })

            if pvalue.disabled == true then inavsuite.app.formFields[pidx]:enable(false) end

            if inavsuite.preferences.menulastselected["servos"] == pidx then inavsuite.app.formFields[pidx]:focus() end

            lc = lc + 1

            if lc == numPerRow then lc = 0 end
        end
    end

    inavsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

local function getServoCount(callback, callbackParam)
    local message = {
        command = 120, -- MSP_SERVO_CONFIGURATIONS
        processReply = function(self, buf)
            local servoCount = inavsuite.tasks.msp.mspHelper.readU8(buf)

            -- update master one in case changed
            inavsuite.session.servoCountNew = servoCount

            if callback then callback(callbackParam) end
        end,
        -- 2 servos
        -- simulatorResponse = {
        --        2,
        --        220, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0,
        --        221, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
        -- }
        -- 4 servos
        simulatorResponse = {4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0, 120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0}
    }
    inavsuite.tasks.msp.mspQueue:add(message)
end

local function openPageInit(pidx, title, script)

    if inavsuite.session.servoCount ~= nil then
        buildServoTable()
        openPage(pidx, title, script)
    else
        local message = {
            command = 120, -- MSP_SERVO_CONFIGURATIONS
            processReply = function(self, buf)
                if #buf >= 10 then
                    local servoCount = inavsuite.tasks.msp.mspHelper.readU8(buf)

                    -- update master one in case changed
                    inavsuite.session.servoCount = servoCount
                end
            end,
            simulatorResponse = {4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0, 120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0}
        }
        inavsuite.tasks.msp.mspQueue:add(message)

        local message = {
            command = 192, -- MSP_SERVO_OVERIDE
            processReply = function(self, buf)
                if #buf >= 10 then

                    for i = 0, inavsuite.session.servoCount do
                        buf.offset = i
                        local servoOverride = inavsuite.tasks.msp.mspHelper.readU8(buf)
                        if servoOverride == 0 then
                            inavsuite.utils.log("Servo override: true","debug")
                            inavsuite.session.servoOverride = true
                        end
                    end
                end
                if inavsuite.session.servoOverride == nil then inavsuite.session.servoOverride = false end
            end,
            simulatorResponse = {209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7}
        }
        inavsuite.tasks.msp.mspQueue:add(message)

    end
end

local function event(widget, category, value, x, y)


end

local function onToolMenu(self)

    local buttons
    if inavsuite.session.servoOverride == false then
        buttons = {{
            label = i18n("app.btn_ok_long"),
            action = function()

                -- we cant launch the loader here to se rely on the modules
                -- wakeup function to do this
                triggerOverRide = true
                triggerOverRideAll = true
                return true
            end
        }, {
            label = "CANCEL",
            action = function()
                return true
            end
        }}
    else
        buttons = {{
            label = i18n("app.btn_ok_long"),
            action = function()

                -- we cant launch the loader here to se rely on the modules
                -- wakeup function to do this
                triggerOverRide = true
                return true
            end
        }, {
            label = i18n("app.btn_cancel"),
            action = function()
                return true
            end
        }}
    end
    local message
    local title
    if inavsuite.session.servoOverride == false then
        title = i18n("app.modules.servos.enable_servo_override")
        message = i18n("app.modules.servos.enable_servo_override_msg")
    else
        title = i18n("app.modules.servos.disable_servo_override")
        message = i18n("app.modules.servos.disable_servo_override_msg")
    end

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

local function wakeup()
    if triggerOverRide == true then
        triggerOverRide = false

        if inavsuite.session.servoOverride == false then
            inavsuite.app.audio.playServoOverideEnable = true
            inavsuite.app.ui.progressDisplay(i18n("app.modules.servos.servo_override"), i18n("app.modules.servos.enabling_servo_override"))
            inavsuite.app.Page.servoCenterFocusAllOn(self)
            inavsuite.session.servoOverride = true
        else
            inavsuite.app.audio.playServoOverideDisable = true
            inavsuite.app.ui.progressDisplay(i18n("app.modules.servos.servo_override"), i18n("app.modules.servos.disabling_servo_override"))
            inavsuite.app.Page.servoCenterFocusAllOff(self)
            inavsuite.session.servoOverride = false
        end
    end

    local now = os.clock()
    if ((now - lastServoCountTime) >= 2) and inavsuite.tasks.msp.mspQueue:isProcessed() then
        lastServoCountTime = now

        getServoCount()

        if inavsuite.session.servoCountNew ~= nil then if inavsuite.session.servoCountNew ~= inavsuite.session.servoCount then inavsuite.app.triggers.triggerReloadNoPrompt = true end end

    end

end

local function servoCenterFocusAllOn(self)

    inavsuite.app.audio.playServoOverideEnable = true

    for i = 0, #servoTable do
        local message = {
            command = 193, -- MSP_SET_SERVO_OVERRIDE
            payload = {i}
        }
        inavsuite.tasks.msp.mspHelper.writeU16(message.payload, 0)
        inavsuite.tasks.msp.mspQueue:add(message)
    end
    inavsuite.app.triggers.isReady = true
    inavsuite.app.triggers.closeProgressLoader = true
end

local function servoCenterFocusAllOff(self)

    for i = 0, #servoTable do
        local message = {
            command = 193, -- MSP_SET_SERVO_OVERRIDE
            payload = {i}
        }
        inavsuite.tasks.msp.mspHelper.writeU16(message.payload, 2001)
        inavsuite.tasks.msp.mspQueue:add(message)
    end
    inavsuite.app.triggers.isReady = true
    inavsuite.app.triggers.closeProgressLoader = true
end

local function onNavMenu(self)

    if inavsuite.session.servoOverride == true or inFocus == true then
        inavsuite.app.audio.playServoOverideDisable = true
        inavsuite.session.servoOverride = false
        inFocus = false
        inavsuite.app.ui.progressDisplay(i18n("app.modules.servos.servo_override"), i18n("app.modules.servos.disabling_servo_override"))
        inavsuite.app.Page.servoCenterFocusAllOff(self)
        inavsuite.app.triggers.closeProgressLoader = true
    end
    -- inavsuite.app.ui.progressDisplay()
    if  inavsuite.app.lastMenu == nil then
        inavsuite.app.ui.openMainMenu()
    else
        inavsuite.app.ui.openMainMenuSub(inavsuite.app.lastMenu)
    end

end

local function onReloadMenu()
    inavsuite.app.triggers.triggerReloadFull = true
end

-- not changing to custom api at present due to complexity of read/write scenario in these modules
return {
    event = event,
    openPage = openPageInit,
    onToolMenu = onToolMenu,
    onNavMenu = onNavMenu,
    servoCenterFocusAllOn = servoCenterFocusAllOn,
    servoCenterFocusAllOff = servoCenterFocusAllOff,
    wakeup = wakeup,
    navButtons = {
        menu = true,
        save = false,
        reload = true,
        tool = true,
        help = true
    },
    onReloadMenu = onReloadMenu,    
    API = {},
}
