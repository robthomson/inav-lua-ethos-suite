local pages = {}

local mspSignature
local mspHeaderBytes
local mspBytes
local simulatorResponse
local escDetails = {}
local foundESC = false
local foundESCupdateTag = false
local showPowerCycleLoader = false
local showPowerCycleLoaderInProgress = false
local ESC
local powercycleLoader
local powercycleLoaderCounter = 0
local powercycleLoaderRateLimit = 2
local showPowerCycleLoaderFinished = false

local i18n = inavsuite.i18n.get

local modelField
local versionField
local firmwareField

local findTimeoutClock = os.clock()
local findTimeout = math.floor(inavsuite.tasks.msp.protocol.pageReqTimeout * 0.5)

local modelLine
local modelText
local modelTextPos = {x = 0, y = inavsuite.app.radio.linePaddingTop, w = inavsuite.app.lcdWidth, h = inavsuite.app.radio.navbuttonHeight}

local function getESCDetails()

    if inavsuite.session.escDetails ~= nil then
        escDetails = inavsuite.session.escDetails
        foundESC = true 
        return
    end

    if foundESC == true then 
        return
    end

    local message = {
        command = 217, -- MSP_STATUS
        processReply = function(self, buf)

            local mspBytesCheck = 2 -- we query 2 only unless the flack to cache the init buffer is set
            if ESC and ESC.mspBufferCache == true then
                mspBytesCheck = mspBytes
            end
 
            --if #buf >= mspBytesCheck and buf[1] == mspSignature then
            if buf[1] == mspSignature then
                escDetails.model = ESC.getEscModel(buf)
                escDetails.version = ESC.getEscVersion(buf)
                escDetails.firmware = ESC.getEscFirmware(buf)

                inavsuite.session.escDetails = escDetails

                if ESC.mspBufferCache == true then
                    inavsuite.session.escBuffer = buf 
                end    

                if escDetails.model ~= nil  then
                    foundESC = true
                end

            end

        end,
        uuid = "123e4567-e89b-12d3-b456-426614174201",
        simulatorResponse = simulatorResponse
    }

    inavsuite.tasks.msp.mspQueue:add(message)
end

local function openPage(pidx, title, script)

    inavsuite.app.lastIdx = pidx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    

    local folder = title

    ESC = assert(inavsuite.compiler.loadfile("app/modules/esc_tools/mfg/" .. folder .. "/init.lua"))()

    if ESC.mspapi ~= nil then
        -- we are using the api so get values from that!
        local API = inavsuite.tasks.msp.api.load(ESC.mspapi)
        mspSignature = API.mspSignature
        mspHeaderBytes = API.mspHeaderBytes
        simulatorResponse = API.simulatorResponse or {0}
        mspBytes = #simulatorResponse
    else
        --legacy method
        mspSignature = ESC.mspSignature
        mspHeaderBytes = ESC.mspHeaderBytes
        simulatorResponse = ESC.simulatorResponse
        mspBytes = ESC.mspBytes
    end    

    inavsuite.app.formFields = {}
    inavsuite.app.formLines = {}


    local windowWidth = inavsuite.app.lcdWidth
    local windowHeight = inavsuite.app.lcdHeight

    local y = inavsuite.app.radio.linePaddingTop

    form.clear()

    line = form.addLine(i18n("app.modules.esc_tools.name") .. ' / ' .. ESC.toolName)

    buttonW = 100
    local x = windowWidth - buttonW

    inavsuite.app.formNavigationFields['menu'] = form.addButton(line, {x = x - buttonW - 5, y = inavsuite.app.radio.linePaddingTop, w = buttonW, h = inavsuite.app.radio.navbuttonHeight}, {
        text = i18n("app.navigation_menu"),
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            inavsuite.app.ui.openPage(pidx, i18n("app.modules.esc_tools.name"), "esc_tools/esc.lua")

        end
    })
    inavsuite.app.formNavigationFields['menu']:focus()

    inavsuite.app.formNavigationFields['refresh'] = form.addButton(line, {x = x, y = inavsuite.app.radio.linePaddingTop, w = buttonW, h = inavsuite.app.radio.navbuttonHeight}, {
        text = i18n("app.navigation_reload"),
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            inavsuite.app.Page = nil
            local foundESC = false
            local foundESCupdateTag = false
            local showPowerCycleLoader = false
            local showPowerCycleLoaderInProgress = false
            inavsuite.app.triggers.triggerReloadFull = true
        end
    })
    inavsuite.app.formNavigationFields['menu']:focus()

    ESC.pages = assert(inavsuite.compiler.loadfile("app/modules/esc_tools/mfg/" .. folder .. "/pages.lua"))()

    modelLine = form.addLine("")
    modelText = form.addStaticText(modelLine, modelTextPos, "")

    local buttonW
    local buttonH
    local padding
    local numPerRow

    if inavsuite.preferences.general.iconsize == nil or inavsuite.preferences.general.iconsize == "" then
        inavsuite.preferences.general.iconsize = 1
    else
        inavsuite.preferences.general.iconsize = tonumber(inavsuite.preferences.general.iconsize)
    end

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

    if inavsuite.app.gfx_buttons["esctool"] == nil then inavsuite.app.gfx_buttons["esctool"] = {} end
    if inavsuite.preferences.menulastselected["esctool"] == nil then inavsuite.preferences.menulastselected["esctool"] = 1 end

    for pidx, pvalue in ipairs(ESC.pages) do 


        local section = pvalue
        local hideSection =
            (section.ethosversion and inavsuite.session.ethosRunningVersion < section.ethosversion) or
            (section.mspversion   and inavsuite.utils.apiVersionCompare("<", section.mspversion))
                            --or
                            --(section.developer and not inavsuite.preferences.developer.devtools)

        if not pvalue.disablebutton or (pvalue and pvalue.disablebutton(mspBytes) == false) or not hideSection then

            if lc == 0 then
                if inavsuite.preferences.general.iconsize == 0 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
                if inavsuite.preferences.general.iconsize == 1 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
                if inavsuite.preferences.general.iconsize == 2 then y = form.height() + inavsuite.app.radio.buttonPadding end
            end

            if lc >= 0 then bx = (buttonW + padding) * lc end

            if inavsuite.preferences.general.iconsize ~= 0 then
                if inavsuite.app.gfx_buttons["esctool"][pvalue.image] == nil then inavsuite.app.gfx_buttons["esctool"][pvalue.image] = lcd.loadMask("app/modules/esc_tools/mfg/" .. folder .. "/gfx/" .. pvalue.image) end
            else
                inavsuite.app.gfx_buttons["esctool"][pvalue.image] = nil
            end

            inavsuite.app.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = pvalue.title,
                icon = inavsuite.app.gfx_buttons["esctool"][pvalue.image],
                options = FONT_S,
                paint = function()
                end,
                press = function()
                    inavsuite.preferences.menulastselected["esctool"] = pidx
                    inavsuite.app.ui.progressDisplay()

                    inavsuite.app.ui.openPage(pidx, title, "esc_tools/mfg/" .. folder .. "/pages/" .. pvalue.script)

                end
            })

            if inavsuite.preferences.menulastselected["esctool"] == pidx then inavsuite.app.formFields[pidx]:focus() end

            if inavsuite.app.triggers.escToolEnableButtons == true then
                inavsuite.app.formFields[pidx]:enable(true)
            else
                inavsuite.app.formFields[pidx]:enable(false)
            end

            lc = lc + 1

            if lc == numPerRow then lc = 0 end
        end

    end

    inavsuite.app.triggers.escToolEnableButtons = false
    --getESCDetails()
    collectgarbage()
end

local function wakeup()

    if foundESC == false and inavsuite.tasks.msp.mspQueue:isProcessed() then getESCDetails() end

    -- enable the form
    if foundESC == true and foundESCupdateTag == false then
        foundESCupdateTag = true

        if escDetails.model ~= nil and escDetails.model ~= nil and escDetails.firmware ~= nil then
            local text = escDetails.model .. " " .. escDetails.version .. " " .. escDetails.firmware
            inavsuite.escHeaderLineText = text
            modelText = form.addStaticText(modelLine, modelTextPos, text)
        end

        for i, v in ipairs(inavsuite.app.formFields) do inavsuite.app.formFields[i]:enable(true) end

        if ESC and ESC.powerCycle == true and showPowerCycleLoader == true then
            powercycleLoader:close()
            powercycleLoaderCounter = 0
            showPowerCycleLoaderInProgress = false
            showPowerCycleLoader = false
            showPowerCycleLoaderFinished = true
            inavsuite.app.triggers.isReady = true
        end

        inavsuite.app.triggers.closeProgressLoader = true

    end

    if showPowerCycleLoaderFinished == false and foundESCupdateTag == false and showPowerCycleLoader == false and ((findTimeoutClock <= os.clock() - findTimeout) or inavsuite.app.dialogs.progressCounter >= 101) then
        inavsuite.app.dialogs.progress:close()
        inavsuite.app.dialogs.progressDisplay = false
        inavsuite.app.triggers.isReady = true

        if ESC and ESC.powerCycle ~= true then modelText = form.addStaticText(modelLine, modelTextPos, i18n("app.modules.esc_tools.unknown")) end

        if ESC and ESC.powerCycle == true then showPowerCycleLoader = true end

    end

    if showPowerCycleLoaderInProgress == true then

        local now = os.clock()
        if (now - powercycleLoaderRateLimit) >= 2 then

            getESCDetails()

            powercycleLoaderRateLimit = now
            powercycleLoaderCounter = powercycleLoaderCounter + 5
            powercycleLoader:value(powercycleLoaderCounter)

            if powercycleLoaderCounter >= 100 then
                powercycleLoader:close()
                modelText = form.addStaticText(modelLine, modelTextPos, i18n("app.modules.esc_tools.unknown"))
                showPowerCycleLoaderInProgress = false
                inavsuite.app.triggers.disableRssiTimeout = false
                showPowerCycleLoader = false
                inavsuite.app.audio.playTimeout = true
                showPowerCycleLoaderFinished = true
                inavsuite.app.triggers.isReady = false
            end

        end

    end

    if showPowerCycleLoader == true then
        if showPowerCycleLoaderInProgress == false then
            showPowerCycleLoaderInProgress = true
            inavsuite.app.audio.playEscPowerCycle = true
            inavsuite.app.triggers.disableRssiTimeout = true
            powercycleLoader = form.openProgressDialog(i18n("app.modules.esc_tools.searching"), i18n("app.modules.esc_tools.please_powercycle"))
            powercycleLoader:value(0)
            powercycleLoader:closeAllowed(false)
        end
    end

end

local function event(widget, category, value, x, y)

    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        if powercycleLoader then powercycleLoader:close() end
        inavsuite.app.ui.openPage(pidx, i18n("app.modules.esc_tools.name"), "esc_tools/esc.lua")
        return true
    end


end

return {
    openPage = openPage,
    wakeup = wakeup,
    event = event,
    API = {}
}
