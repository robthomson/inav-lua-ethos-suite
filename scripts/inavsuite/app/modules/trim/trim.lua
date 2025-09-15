local labels = {}
local fields = {}
local i18n = inavsuite.i18n.get
local triggerOverRide = false
local inOverRide = false
local lastChangeTime = os.clock()
local currentRollTrim
local currentRollTrimLast
local currentPitchTrim
local currentPitchTrimLast
local currentCollectiveTrim
local currentCollectiveTrimLast
local currentYawTrim
local currentYawTrimLast
local currentIdleThrottleTrim
local currentIdleThrottleTrimLast
local clear2send = true


local apidata = {
    api = {
        [1] = "MIXER_CONFIG",
    },
    formdata = {
        labels = {
        },
        fields = {
            {t = i18n("app.modules.trim.roll_trim"),         mspapi = 1, apikey = "swash_trim_0"},
            {t = i18n("app.modules.trim.pitch_trim"),        mspapi = 1, apikey = "swash_trim_1"},
            {t = i18n("app.modules.trim.collective_trim"),   mspapi = 1, apikey = "swash_trim_2"},
            {t = i18n("app.modules.trim.tail_motor_idle"),   mspapi = 1, apikey = "tail_motor_idle", enablefunction = function() return (inavsuite.session.tailMode >= 1) end},
            {t = i18n("app.modules.trim.yaw_trim"),          mspapi = 1, apikey = "tail_center_trim", enablefunction = function() return (inavsuite.session.tailMode == 0) end }
        }
    }                 
}



local function saveData()
    clear2send = true
    inavsuite.app.triggers.triggerSaveNoProgress = true
end

local function mixerOn(self)

    inavsuite.app.audio.playMixerOverideEnable = true

    for i = 1, 4 do
        local message = {
            command = 191, -- MSP_SET_MIXER_OVERRIDE
            payload = {i}
        }

        inavsuite.tasks.msp.mspHelper.writeU16(message.payload, 0)
        inavsuite.tasks.msp.mspQueue:add(message)

        if inavsuite.preferences.developer.logmsp then
            local logData = "mixerOn: {" .. inavsuite.utils.joinTableItems(message.payload, ", ") .. "}"
            inavsuite.utils.log(logData,"info")
        end

    end



    inavsuite.app.triggers.isReady = true
    inavsuite.app.triggers.closeProgressLoader = true
end

local function mixerOff(self)

    inavsuite.app.audio.playMixerOverideDisable = true

    for i = 1, 4 do
        local message = {
            command = 191, -- MSP_SET_MIXER_OVERRIDE
            payload = {i}
        }
        inavsuite.tasks.msp.mspHelper.writeU16(message.payload, 2501)
        inavsuite.tasks.msp.mspQueue:add(message)

        if inavsuite.preferences.developer.logmsp then
            local logData = "mixerOff: {" .. inavsuite.utils.joinTableItems(message.payload, ", ") .. "}"
            inavsuite.utils.log(logData,"info")
        end

    end



    inavsuite.app.triggers.isReady = true
    inavsuite.app.triggers.closeProgressLoader = true
end

local function postLoad(self)

    if inavsuite.session.tailMode == nil then
        local v = inavsuite.app.Page.values['MIXER_CONFIG']["tail_rotor_mode"]
        inavsuite.session.tailMode = math.floor(v)
        inavsuite.app.triggers.reload = true
        return
    end

    -- existing
    currentRollTrim = inavsuite.app.Page.fields[1].value
    currentPitchTrim = inavsuite.app.Page.fields[2].value
    currentCollectiveTrim = inavsuite.app.Page.fields[3].value

    if inavsuite.session.tailModeActive == 1 or inavsuite.session.tailModeActive == 2 then currentIdleThrottleTrim = inavsuite.app.Page.fields[4].value end

    if inavsuite.session.tailModeActive == 0 then currentYawTrim = inavsuite.app.Page.fields[4].value end
    inavsuite.app.triggers.closeProgressLoader = true
end

local function wakeup(self)

    -- filter changes to mixer - essentially preventing queue getting flooded	
    if inOverRide == true then

        currentRollTrim = inavsuite.app.Page.fields[1].value
        local now = os.clock()
        local settleTime = 0.85
        if ((now - lastChangeTime) >= settleTime) and inavsuite.tasks.msp.mspQueue:isProcessed() and clear2send == true then
            if currentRollTrim ~= currentRollTrimLast then
                currentRollTrimLast = currentRollTrim
                lastChangeTime = now
                inavsuite.utils.log("save trim","debug")
                self.saveData(self)
            end
        end

        currentPitchTrim = inavsuite.app.Page.fields[2].value
        local now = os.clock()
        local settleTime = 0.85
        if ((now - lastChangeTime) >= settleTime) and inavsuite.tasks.msp.mspQueue:isProcessed() and clear2send == true then
            if currentPitchTrim ~= currentPitchTrimLast then
                currentPitchTrimLast = currentPitchTrim
                lastChangeTime = now
                self.saveData(self)
            end
        end

        currentCollectiveTrim = inavsuite.app.Page.fields[3].value
        local now = os.clock()
        local settleTime = 0.85
        if ((now - lastChangeTime) >= settleTime) and inavsuite.tasks.msp.mspQueue:isProcessed() and clear2send == true then
            if currentCollectiveTrim ~= currentCollectiveTrimLast then
                currentCollectiveTrimLast = currentCollectiveTrim
                lastChangeTime = now
                self.saveData(self)
            end
        end

        if inavsuite.session.tailMode == 1 or inavsuite.session.tailMode == 2 then
            currentIdleThrottleTrim = inavsuite.app.Page.fields[4].value
            local now = os.clock()
            local settleTime = 0.85
            if ((now - lastChangeTime) >= settleTime) and inavsuite.tasks.msp.mspQueue:isProcessed() and clear2send == true then
                if currentIdleThrottleTrim ~= currentIdleThrottleTrimLast then
                    currentIdleThrottleTrimLast = currentIdleThrottleTrim
                    lastChangeTime = now
                    self.saveData(self)
                end
            end
        end

        if inavsuite.session.tailMode == 0 then
            currentYawTrim = inavsuite.app.Page.fields[4].value
            local now = os.clock()
            local settleTime = 0.85
            if ((now - lastChangeTime) >= settleTime) and inavsuite.tasks.msp.mspQueue:isProcessed() then
                if currentYawTrim ~= currentYawTrimLast then
                    currentYawTrimLast = currentYawTrim
                    lastChangeTime = now
                    self.saveData(self)
                end
            end
        end

    end

    if triggerOverRide == true then
        triggerOverRide = false

        if inOverRide == false then

            inavsuite.app.audio.playMixerOverideEnable = true

            inavsuite.app.ui.progressDisplay(i18n("app.modules.trim.mixer_override"), i18n("app.modules.trim.mixer_override_enabling"))

            inavsuite.app.Page.mixerOn(self)
            inOverRide = true
        else

            inavsuite.app.audio.playMixerOverideDisable = true

            inavsuite.app.ui.progressDisplay(i18n("app.modules.trim.mixer_override"), i18n("app.modules.trim.mixer_override_disabling"))

            inavsuite.app.Page.mixerOff(self)
            inOverRide = false
        end
    end

end

local function onToolMenu(self)

    local buttons = {{
        label = i18n("app.btn_ok"),
        action = function()

            -- we cant launch the loader here to se rely on the modules
            -- wakup function to do this
            triggerOverRide = true
            return true
        end
    }, {
        label = i18n("app.btn_cancel"),
        action = function()
            return true
        end
    }}
    local message
    local title
    if inOverRide == false then
        title = i18n("app.modules.trim.enable_mixer_override")
        message = i18n("app.modules.trim.enable_mixer_message")
    else
        title = i18n("app.modules.trim.disable_mixer_override")
        message = i18n("app.modules.trim.disable_mixer_message")
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

local function onNavMenu(self)

    if inOverRide == true or inFocus == true then
        inavsuite.app.audio.playMixerOverideDisable = true

        inOverRide = false
        inFocus = false

        inavsuite.app.ui.progressDisplay(i18n("app.modules.trim.mixer_override"), i18n("app.modules.trim.mixer_override_disabling"))

        mixerOff(self)
        inavsuite.app.triggers.closeProgressLoader = true
    end

    if  inavsuite.app.lastMenu == nil then
        inavsuite.app.ui.openMainMenu()
    else
        inavsuite.app.ui.openMainMenuSub(inavsuite.app.lastMenu)
    end

end

return {
    apidata = apidata,
    eepromWrite = true,
    reboot = false,
    mixerOff = mixerOff,
    mixerOn = mixerOn,
    postLoad = postLoad,
    onToolMenu = onToolMenu,
    onNavMenu = onNavMenu,
    wakeup = wakeup,
    saveData = saveData,
    navButtons = {
        menu = true,
        save = true,
        reload = true,
        tool = true,
        help = true
    },
    API = {},
}
