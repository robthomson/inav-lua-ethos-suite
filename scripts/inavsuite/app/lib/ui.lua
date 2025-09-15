--[[
  Copyright (C) Rotorflight Project

  License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License version 3 as published by the Free
  Software Foundation.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  Note: Some icons sourced from https://www.flaticon.com/
]]--

local ui = {}

local arg   = { ... }
local config = arg[1]
local i18n  = inavsuite.i18n.get

--------------------------------------------------------------------------------
-- Progress dialogs
--------------------------------------------------------------------------------

-- Show a progress dialog (defaults: "Loading" / "Loading data from flight controller...").
function ui.progressDisplay(title, message, speed)
    if inavsuite.app.dialogs.progressDisplay then return end

    title   = title   or i18n("app.msg_loading")
    message = message or i18n("app.msg_loading_from_fbl")


    if speed then
        inavsuite.app.dialogs.progressSpeed = true
    else
        inavsuite.app.dialogs.progressSpeed = false
    end

    inavsuite.app.dialogs.progressDisplay   = true
    inavsuite.app.dialogs.progressWatchDog  = os.clock()
    inavsuite.app.dialogs.progress = form.openProgressDialog({
        title   = title,
        message = message,
        close   = function() end,
        wakeup  = function()
            local app = inavsuite.app

            app.dialogs.progress:value(app.dialogs.progressCounter)

            local mult = 1
            if app.dialogs.progressSpeed then
                mult = 2
            end

            local isProcessing = (app.Page and app.Page.apidata and app.Page.apidata.apiState and app.Page.apidata.apiState.isProcessing) or false
            local apiV = tostring(inavsuite.session.apiVersion)

            if not app.triggers.closeProgressLoader then
                app.dialogs.progressCounter = app.dialogs.progressCounter + (2 * mult)
                if app.dialogs.progressCounter > 50 and inavsuite.session.apiVersion and not inavsuite.utils.stringInArray(inavsuite.config.supportedMspApiVersion, apiV) then
                    print("No API version yet")
                end
            elseif isProcessing then
                app.dialogs.progressCounter = app.dialogs.progressCounter + (3 * mult)
            elseif app.triggers.closeProgressLoader and inavsuite.tasks.msp and inavsuite.tasks.msp.mspQueue:isProcessed() then   -- this is the one we normally catch
                app.dialogs.progressCounter = app.dialogs.progressCounter + (15 * mult)
                if app.dialogs.progressCounter >= 100 then
                    app.dialogs.progress:close()
                    app.dialogs.progressDisplay = false
                    app.dialogs.progressCounter = 0
                    app.triggers.closeProgressLoader = false
                end
            elseif app.triggers.closeProgressLoader and  app.triggers.closeProgressLoaderNoisProcessed then   -- an oddball for things where we dont want to check against isProcessed
                app.dialogs.progressCounter = app.dialogs.progressCounter + (15 * mult)
                if app.dialogs.progressCounter >= 100 then
                    app.dialogs.progress:close()
                    app.dialogs.progressDisplay = false
                    app.dialogs.progressCounter = 0
                    app.triggers.closeProgressLoader = false
                    app.dialogs.progressSpeed = false
                    app.triggers.closeProgressLoaderNoisProcessed= false
                end
            end

            -- Timeout (hard timeout)
            if app.dialogs.progressWatchDog
               and inavsuite.tasks.msp
               and (os.clock() - app.dialogs.progressWatchDog) > tonumber(inavsuite.tasks.msp.protocol.pageReqTimeout) 
               and app.dialogs.progressDisplay == true then
                app.audio.playTimeout = true
                app.dialogs.progress:message(i18n("app.error_timed_out"))
                app.dialogs.progress:closeAllowed(true)
                app.dialogs.progress:value(100)
                app.Page   = app.PageTmp
                app.PageTmp = nil
                app.dialogs.progressCounter = 0
                app.dialogs.progressSpeed = false
                app.dialogs.progressDisplay = false
            end

            if not inavsuite.tasks.msp  then
                app.dialogs.progressCounter = app.dialogs.progressCounter + (2 * mult)
                if app.dialogs.progressCounter >= 100 then
                    app.dialogs.progress:close()
                    app.dialogs.progressDisplay = false
                    app.dialogs.progressCounter = 0
                    app.dialogs.progressSpeed = false
                end
            end

        end
    })

    inavsuite.app.dialogs.progressCounter = 0
    inavsuite.app.dialogs.progress:value(0)
    inavsuite.app.dialogs.progress:closeAllowed(false)
end

-- Show a "Saving…" progress dialog.
function ui.progressDisplaySave(message)
    local app = inavsuite.app

    inavsuite.app.dialogs.saveDisplay  = true
    inavsuite.app.dialogs.saveWatchDog = os.clock()

    local msg = ({
        [app.pageStatus.saving]      = "app.msg_saving_settings",
        [app.pageStatus.eepromWrite] = "app.msg_saving_settings",
        [app.pageStatus.rebooting]   = "app.msg_rebooting"
    })[app.pageState]

    if not message then message = i18n(msg) end
    local title = i18n("app.msg_saving")

    inavsuite.app.dialogs.save = form.openProgressDialog({
        title   = title,
        message = message,
        close   = function() end,
        wakeup  = function()
            local app = inavsuite.app

            app.dialogs.save:value(app.dialogs.saveProgressCounter)

            local isProcessing = (app.Page and app.Page.apidata and app.Page.apidata.apiState and app.Page.apidata.apiState.isProcessing) or false

            if not app.dialogs.saveProgressCounter then
                app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 1
            elseif isProcessing then
                app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 3        
            elseif app.triggers.closeSaveFake then
                app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 5
                if app.dialogs.saveProgressCounter >= 100 then
                    app.triggers.closeSaveFake      = false
                    app.dialogs.saveProgressCounter = 0
                    app.dialogs.saveDisplay         = false
                    app.dialogs.saveWatchDog        = nil
                    app.dialogs.save:close()
                end           
            elseif inavsuite.tasks.msp.mspQueue:isProcessed() then
                app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 15
                if app.dialogs.saveProgressCounter >= 100 then
                    app.dialogs.save:close()
                    app.dialogs.saveDisplay         = false
                    app.dialogs.saveProgressCounter = 0
                    app.triggers.closeSave          = false
                    app.triggers.isSaving           = false
                end
            else
                app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 2
            end

            local timeout = tonumber(inavsuite.tasks.msp.protocol.saveTimeout + 5)
            if (app.dialogs.saveWatchDog and (os.clock() - app.dialogs.saveWatchDog) > timeout)
               or (app.dialogs.saveProgressCounter > 120 and inavsuite.tasks.msp.mspQueue:isProcessed()) 
               and app.dialogs.saveDisplay == true then

                app.audio.playTimeout = true
                app.dialogs.save:message(i18n("app.error_timed_out"))
                app.dialogs.save:closeAllowed(true)
                app.dialogs.save:value(100)
                app.dialogs.saveProgressCounter = 0
                app.dialogs.saveDisplay         = false
                app.triggers.isSaving           = false
                app.Page   = app.PageTmp
                app.PageTmp = nil
            end
        end
    })

    inavsuite.app.dialogs.save:value(0)
    inavsuite.app.dialogs.save:closeAllowed(false)
end

-- Is any progress-related dialog showing?
function ui.progressDisplayIsActive()
    return inavsuite.app.dialogs.progressDisplay
        or inavsuite.app.dialogs.saveDisplay
        or inavsuite.app.dialogs.progressDisplayEsc
        or inavsuite.app.dialogs.nolinkDisplay
        or inavsuite.app.dialogs.badversionDisplay
end

--------------------------------------------------------------------------------
-- Enable/disable fields
--------------------------------------------------------------------------------

function ui.disableAllFields()
    for i = 1, #inavsuite.app.formFields do
        local field = inavsuite.app.formFields[i]
        if type(field) == "userdata" then field:enable(false) end
    end
end

function ui.enableAllFields()
    for _, field in ipairs(inavsuite.app.formFields) do
        if type(field) == "userdata" then field:enable(true) end
    end
end

function ui.disableAllNavigationFields()
    for _, v in pairs(inavsuite.app.formNavigationFields) do
        v:enable(false)
    end
end

function ui.enableAllNavigationFields()
    for _, v in pairs(inavsuite.app.formNavigationFields) do
        v:enable(true)
    end
end

function ui.enableNavigationField(x)
    local field = inavsuite.app.formNavigationFields[x]
    if field then field:enable(true) end
end

function ui.disableNavigationField(x)
    local field = inavsuite.app.formNavigationFields[x]
    if field then field:enable(false) end
end

--------------------------------------------------------------------------------
-- Main menu
--------------------------------------------------------------------------------

-- Open main menu.
function ui.openMainMenu()
    inavsuite.app.formFields         = {}
    inavsuite.app.formFieldsOffline  = {}
    inavsuite.app.formFieldsBGTask   = {}
    inavsuite.app.formLines          = {}
    inavsuite.app.lastLabel          = nil
    inavsuite.app.isOfflinePage      = false

    if inavsuite.tasks.msp then
        inavsuite.tasks.msp.protocol.mspIntervalOveride = nil
    end

    inavsuite.app.gfx_buttons["mainmenu"] = {}
    inavsuite.app.lastMenu = nil

    -- Clear old icons.
    for k in pairs(inavsuite.app.gfx_buttons) do
        if k ~= "mainmenu" then inavsuite.app.gfx_buttons[k] = nil end
    end

    inavsuite.app.triggers.isReady = false
    inavsuite.app.uiState          = inavsuite.app.uiStatus.mainMenu

    form.clear()

    inavsuite.app.lastIdx   = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    ESC = {}

    -- Icon size
    if inavsuite.preferences.general.iconsize == nil or inavsuite.preferences.general.iconsize == "" then
        inavsuite.preferences.general.iconsize = 1
    else
        inavsuite.preferences.general.iconsize = tonumber(inavsuite.preferences.general.iconsize)
    end

    -- Dimensions
    local w, h = lcd.getWindowSize()
    local windowWidth  = w
    local windowHeight = h

    local buttonW, buttonH, padding, numPerRow

    if inavsuite.preferences.general.iconsize == 0 then
        padding   = inavsuite.app.radio.buttonPaddingSmall
        buttonW   = (inavsuite.app.lcdWidth - padding) / inavsuite.app.radio.buttonsPerRow - padding
        buttonH   = inavsuite.app.radio.navbuttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    elseif inavsuite.preferences.general.iconsize == 1 then
        padding   = inavsuite.app.radio.buttonPaddingSmall
        buttonW   = inavsuite.app.radio.buttonWidthSmall
        buttonH   = inavsuite.app.radio.buttonHeightSmall
        numPerRow = inavsuite.app.radio.buttonsPerRowSmall
    elseif inavsuite.preferences.general.iconsize == 2 then
        padding   = inavsuite.app.radio.buttonPadding
        buttonW   = inavsuite.app.radio.buttonWidth
        buttonH   = inavsuite.app.radio.buttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end

    inavsuite.app.gfx_buttons["mainmenu"] = inavsuite.app.gfx_buttons["mainmenu"] or {}
    inavsuite.preferences.menulastselected["mainmenu"] =
        inavsuite.preferences.menulastselected["mainmenu"] or 1

    local Menu = assert(inavsuite.compiler.loadfile("app/modules/sections.lua"))()

    local lc, bx, y = 0, 0, 0

    local header = form.addLine("Configuration")

    for pidx, pvalue in ipairs(Menu) do
        if not pvalue.developer then
            inavsuite.app.formFieldsOffline[pidx] = pvalue.offline or false
            inavsuite.app.formFieldsBGTask[pidx] = pvalue.bgtask or false

            if pvalue.newline then
                lc = 0
                form.addLine("System")
            end

            if lc == 0 then
                y = form.height() +
                    ((inavsuite.preferences.general.iconsize == 2) and inavsuite.app.radio.buttonPadding
                                                                  or inavsuite.app.radio.buttonPaddingSmall)
            end

            bx = (buttonW + padding) * lc

            if inavsuite.preferences.general.iconsize ~= 0 then
                inavsuite.app.gfx_buttons["mainmenu"][pidx] =
                    inavsuite.app.gfx_buttons["mainmenu"][pidx] or lcd.loadMask(pvalue.image)
            else
                inavsuite.app.gfx_buttons["mainmenu"][pidx] = nil
            end

            inavsuite.app.formFields[pidx] = form.addButton(line, {
                x = bx, y = y, w = buttonW, h = buttonH
            }, {
                text    = pvalue.title,
                icon    = inavsuite.app.gfx_buttons["mainmenu"][pidx],
                options = FONT_S,
                paint   = function() end,
                press   = function()
                    inavsuite.preferences.menulastselected["mainmenu"] = pidx
                    local speed = false
                    if pvalue.loaderspeed then speed = true end
                    inavsuite.app.ui.progressDisplay(nil,nil,speed)
                    if pvalue.module then
                        inavsuite.app.isOfflinePage = true
                        inavsuite.app.ui.openPage(pidx, pvalue.title, pvalue.module .. "/" .. pvalue.script)
                    else
                        inavsuite.app.ui.openMainMenuSub(pvalue.id)
                    end
                end
            })

            if pvalue.disabled then
                inavsuite.app.formFields[pidx]:enable(false)
            end

            if inavsuite.preferences.menulastselected["mainmenu"] == pidx then
                inavsuite.app.formFields[pidx]:focus()
            end

            lc = lc + 1
            if lc == numPerRow then lc = 0 end
        end
    end

    inavsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    inavsuite.utils.reportMemoryUsage("MainMenuSub")
end

-- Open a sub-section of the main menu.
function ui.openMainMenuSub(activesection)
    inavsuite.app.formFields        = {}
    inavsuite.app.formFieldsOffline = {}
    inavsuite.app.formLines         = {}
    inavsuite.app.lastLabel         = nil
    inavsuite.app.isOfflinePage     = false
    inavsuite.app.gfx_buttons[activesection] = {}
    inavsuite.app.lastMenu = activesection

    -- Clear old icons.
    for k in pairs(inavsuite.app.gfx_buttons) do
        if k ~= activesection then inavsuite.app.gfx_buttons[k] = nil end
    end

    -- Hard exit on error.
    if not inavsuite.utils.ethosVersionAtLeast(config.ethosVersion) then return end

    local MainMenu = inavsuite.app.MainMenu

    -- Clear navigation vars.
    inavsuite.app.lastIdx   = nil
    inavsuite.app.lastTitle = nil
    inavsuite.app.lastScript = nil
    inavsuite.session.lastPage = nil
    inavsuite.app.triggers.isReady             = false
    inavsuite.app.uiState                      = inavsuite.app.uiStatus.mainMenu
    inavsuite.app.triggers.disableRssiTimeout  = false

    inavsuite.preferences.general.iconsize = tonumber(inavsuite.preferences.general.iconsize) or 1

    local buttonW, buttonH, padding, numPerRow

    if inavsuite.preferences.general.iconsize == 0 then
        padding   = inavsuite.app.radio.buttonPaddingSmall
        buttonW   = (inavsuite.app.lcdWidth - padding) / inavsuite.app.radio.buttonsPerRow - padding
        buttonH   = inavsuite.app.radio.navbuttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    elseif inavsuite.preferences.general.iconsize == 1 then
        padding   = inavsuite.app.radio.buttonPaddingSmall
        buttonW   = inavsuite.app.radio.buttonWidthSmall
        buttonH   = inavsuite.app.radio.buttonHeightSmall
        numPerRow = inavsuite.app.radio.buttonsPerRowSmall
    elseif inavsuite.preferences.general.iconsize == 2 then
        padding   = inavsuite.app.radio.buttonPadding
        buttonW   = inavsuite.app.radio.buttonWidth
        buttonH   = inavsuite.app.radio.buttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end

    form.clear()

    inavsuite.app.gfx_buttons[activesection] = inavsuite.app.gfx_buttons[activesection] or {}
    inavsuite.preferences.menulastselected[activesection] =
        inavsuite.preferences.menulastselected[activesection] or 1

    for idx, section in ipairs(MainMenu.sections) do
        if section.id == activesection then
            local w, h = lcd.getWindowSize()
            local windowWidth, windowHeight = w, h
            local padding = inavsuite.app.radio.buttonPadding

            form.addLine(section.title)

            local x = windowWidth - 110 -- 100 + 10 padding
            inavsuite.app.formNavigationFields['menu'] = form.addButton(line, {
                x = x, y = inavsuite.app.radio.linePaddingTop, w = 100, h = inavsuite.app.radio.navbuttonHeight
            }, {
                text    = "MENU",
                icon    = nil,
                options = FONT_S,
                paint   = function() end,
                press   = function()
                    inavsuite.app.lastIdx = nil
                    inavsuite.session.lastPage = nil
                    if inavsuite.app.Page and inavsuite.app.Page.onNavMenu then
                        inavsuite.app.Page.onNavMenu(inavsuite.app.Page)
                    end
                    inavsuite.app.ui.openMainMenu()
                end
            })
            inavsuite.app.formNavigationFields['menu']:focus()

            local lc, y = 0, 0

            for pidx, page in ipairs(MainMenu.pages) do
                if page.section == idx then
                local hideEntry =
                    (page.ethosversion and not inavsuite.utils.ethosVersionAtLeast(page.ethosversion))
                    or (page.mspversion and inavsuite.utils.apiVersionCompare("<", page.mspversion))
                    or (page.developer and not inavsuite.preferences.developer.devtools)

                    local offline = page.offline
                    inavsuite.app.formFieldsOffline[pidx] = offline or false

                    if not hideEntry then
                        if lc == 0 then
                            y = form.height() +
                                ((inavsuite.preferences.general.iconsize == 2) and inavsuite.app.radio.buttonPadding
                                                                              or inavsuite.app.radio.buttonPaddingSmall)
                        end

                        local x = (buttonW + padding) * lc

                        if inavsuite.preferences.general.iconsize ~= 0 then
                            inavsuite.app.gfx_buttons[activesection][pidx] =
                                inavsuite.app.gfx_buttons[activesection][pidx]
                                or lcd.loadMask("app/modules/" .. page.folder .. "/" .. page.image)
                        else
                            inavsuite.app.gfx_buttons[activesection][pidx] = nil
                        end

                        inavsuite.app.formFields[pidx] = form.addButton(line, {
                            x = x, y = y, w = buttonW, h = buttonH
                        }, {
                            text    = page.title,
                            icon    = inavsuite.app.gfx_buttons[activesection][pidx],
                            options = FONT_S,
                            paint   = function() end,
                            press   = function()
                                inavsuite.preferences.menulastselected[activesection] = pidx
                                local speed = false
                                if page.loaderspeed or section.loaderspeed then speed = true end
                                inavsuite.app.ui.progressDisplay(nil,nil,speed)
                                inavsuite.app.isOfflinePage = offline
                                inavsuite.app.ui.openPage(pidx, page.title, page.folder .. "/" .. page.script)
                            end
                        })

                        if inavsuite.preferences.menulastselected[activesection] == pidx then
                            inavsuite.app.formFields[pidx]:focus()
                        end

                        lc = (lc + 1) % numPerRow
                    end
                end
            end
        end
    end

    inavsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    inavsuite.utils.reportMemoryUsage("MainMenuSub")
end

--------------------------------------------------------------------------------
-- Labels / fields
--------------------------------------------------------------------------------

-- Find a label by id on a page table.
function ui.getLabel(id, page)
    if id == nil then return nil end
    for i = 1, #page do
        if page[i].label == id then return page[i] end
    end
    return nil
end

-- Boolean field.
-- Single Boolean field with optional inversion when f.subtype == 1
function ui.fieldBoolean(i)
    local app        = inavsuite.app
    local page       = app.Page
    local fields     = page.fields
    local f          = fields[i]
    local formLines  = app.formLines
    local formFields = app.formFields
    local radioText  = app.radio.text

    -- Defensive guard: field must exist
    if not f then
        ui.disableAllFields()
        ui.disableAllNavigationFields()
        ui.enableNavigationField('menu')
        return
    end

    local invert = (f.subtype == 1)  -- your proposed switch

    local posText, posField

    -- Label / inline handling
    if f.inline and f.inline >= 1 and f.label then
        if radioText == 2 and f.t2 then f.t = f.t2 end
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if f.t then
            if radioText == 2 and f.t2 then f.t = f.t2 end
            if f.label then f.t = "        " .. f.t end
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    -- Helper: decode stored numeric (0/1) -> UI boolean, honoring inversion
    local function decode()
        if not fields or not fields[i] then
            ui.disableAllFields()
            ui.disableAllNavigationFields()
            ui.enableNavigationField('menu')
            return nil
        end
        local v = (fields[i].value == 1) and 1 or 0
        if invert then v = (v == 1) and 0 or 1 end
        return (v == 1)
    end

    -- Helper: encode UI boolean -> stored numeric (0/1), honoring inversion
    local function encode(b)
        local v = b and 1 or 0
        if invert then v = (v == 1) and 0 or 1 end
        return v
    end

    formFields[i] = form.addBooleanField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        function()
            return decode()
        end,
        function(valueBool)
            local value = encode(valueBool == true)
            if f.postEdit then f.postEdit(page, value) end
            if f.onChange then f.onChange(page, value) end
            f.value = inavsuite.app.utils.saveFieldValue(fields[i], value)
        end
    )

    if f.disable then formFields[i]:enable(false) end
end


-- Choice field.
function ui.fieldChoice(i)
    local app        = inavsuite.app
    local page       = app.Page
    local fields     = page.fields
    local f          = fields[i]
    local formLines  = app.formLines
    local formFields = app.formFields
    local radioText  = app.radio.text

    local posText, posField

    if f.inline and f.inline >= 1 and f.label then
        if radioText == 2 and f.t2 then f.t = f.t2 end
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if f.t then
            if radioText == 2 and f.t2 then f.t = f.t2 end
            if f.label then f.t = "        " .. f.t end
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    local tbldata = f.table and inavsuite.app.utils.convertPageValueTable(f.table, f.tableIdxInc) or {}

    formFields[i] = form.addChoiceField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        tbldata,
        function()
            if not fields or not fields[i] then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(fields[i])
        end,
        function(value)
            if f.postEdit then f.postEdit(page, value) end
            if f.onChange then f.onChange(page, value) end
            f.value = inavsuite.app.utils.saveFieldValue(fields[i], value)
        end
    )

    if f.disable then formFields[i]:enable(false) end
end

-- Slider field.
function ui.fieldSlider(i)
    local app        = inavsuite.app
    local page       = app.Page
    local fields     = page.fields
    local f          = fields[i]
    local formLines  = app.formLines
    local formFields = app.formFields

    local posField, posText

    if f.inline and f.inline >= 1 and f.label then
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if f.t then
            if f.label then f.t = "        " .. f.t end
        else
            f.t = ""
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    if f.offset then
        if f.min then f.min = f.min + f.offset end
        if f.max then f.max = f.max + f.offset end
    end

    local minValue = inavsuite.app.utils.scaleValue(f.min, f)
    local maxValue = inavsuite.app.utils.scaleValue(f.max, f)

    if f.mult then
        if minValue then minValue = minValue * f.mult end
        if maxValue then maxValue = maxValue * f.mult end
    end

    minValue = minValue or 0
    maxValue = maxValue or 0

    formFields[i] = form.addSliderField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        minValue,
        maxValue,
        function()
            if not (page.fields and page.fields[i]) then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(page.fields[i])
        end,
        function(value)
            if f.postEdit then f.postEdit(page) end
            if f.onChange then f.onChange(page) end
            f.value = inavsuite.app.utils.saveFieldValue(page.fields[i], value)
        end
    )

    local currentField = formFields[i]

    if f.onFocus  then currentField:onFocus(function() f.onFocus(page) end) end

    if f.decimals then currentField:decimals(f.decimals) end
    if f.step     then currentField:step(f.step)         end
    if f.disable  then currentField:enable(false)        end

    if f.help or f.apikey then
        if not f.help and f.apikey then f.help = f.apikey end
        if app.fieldHelpTxt and app.fieldHelpTxt[f.help] and app.fieldHelpTxt[f.help].t then
            currentField:help(app.fieldHelpTxt[f.help].t)
        end
    end

end

-- Number field.
function ui.fieldNumber(i)
    local app        = inavsuite.app
    local page       = app.Page
    local fields     = page.fields
    local f          = fields[i]
    local formLines  = app.formLines
    local formFields = app.formFields

    local posField, posText

    if f.inline and f.inline >= 1 and f.label then
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if f.t then
            if f.label then f.t = "        " .. f.t end
        else
            f.t = ""
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    if f.offset then
        if f.min then f.min = f.min + f.offset end
        if f.max then f.max = f.max + f.offset end
    end

    local minValue = inavsuite.app.utils.scaleValue(f.min, f)
    local maxValue = inavsuite.app.utils.scaleValue(f.max, f)

    if f.mult then
        if minValue then minValue = minValue * f.mult end
        if maxValue then maxValue = maxValue * f.mult end
    end

    minValue = minValue or 0
    maxValue = maxValue or 0

    formFields[i] = form.addNumberField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        minValue,
        maxValue,
        function()
            if not (page.fields and page.fields[i]) then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(page.fields[i])
        end,
        function(value)
            if f.postEdit then f.postEdit(page) end
            if f.onChange then f.onChange(page) end
            f.value = inavsuite.app.utils.saveFieldValue(page.fields[i], value)
        end
    )

    local currentField = formFields[i]

    if f.onFocus  then currentField:onFocus(function() f.onFocus(page) end) end

    if f.default then
        if f.offset then f.default = f.default + f.offset end
        local default = f.default * inavsuite.app.utils.decimalInc(f.decimals)
        if f.mult then default = default * f.mult end
        local str = tostring(default)
        if str:match("%.0$") then default = math.ceil(default) end
        currentField:default(default)
    else
        currentField:default(0)
    end

    if f.decimals then currentField:decimals(f.decimals) end
    if f.unit     then currentField:suffix(f.unit)       end
    if f.step     then currentField:step(f.step)         end
    if f.disable  then currentField:enable(false)        end

    if f.help or f.apikey then
        if not f.help and f.apikey then f.help = f.apikey end
        if app.fieldHelpTxt and app.fieldHelpTxt[f.help] and app.fieldHelpTxt[f.help].t then
            currentField:help(app.fieldHelpTxt[f.help].t)
        end
    end

    if f.instantChange == false then
        currentField:enableInstantChange(false)
    else
        currentField:enableInstantChange(true)
    end
end

-- Source field.
function ui.fieldSource(i)
    local app        = inavsuite.app
    local page       = app.Page
    local fields     = page.fields
    local f          = fields[i]
    local formLines  = app.formLines
    local formFields = app.formFields

    local posField, posText

    if f.inline and f.inline >= 1 and f.label then
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if f.t then
            if f.label then f.t = "        " .. f.t end
        else
            f.t = ""
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    if f.offset then
        if f.min then f.min = f.min + f.offset end
        if f.max then f.max = f.max + f.offset end
    end

    local minValue = inavsuite.app.utils.scaleValue(f.min, f)
    local maxValue = inavsuite.app.utils.scaleValue(f.max, f)

    if f.mult then
        if minValue then minValue = minValue * f.mult end
        if maxValue then maxValue = maxValue * f.mult end
    end

    minValue = minValue or 0
    maxValue = maxValue or 0

    formFields[i] = form.addSourceField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        function()
            if not (page.fields and page.fields[i]) then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(page.fields[i])
        end,
        function(value)
            if f.postEdit then f.postEdit(page) end
            if f.onChange then f.onChange(page) end
            f.value = inavsuite.app.utils.saveFieldValue(page.fields[i], value)
        end
    )

    local currentField = formFields[i]

    if f.onFocus  then currentField:onFocus(function() f.onFocus(page) end) end

    if f.disable  then currentField:enable(false)        end

end

-- Sensor field.
function ui.fieldSensor(i)
    local app        = inavsuite.app
    local page       = app.Page
    local fields     = page.fields
    local f          = fields[i]
    local formLines  = app.formLines
    local formFields = app.formFields

    local posField, posText

    if f.inline and f.inline >= 1 and f.label then
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if f.t then
            if f.label then f.t = "        " .. f.t end
        else
            f.t = ""
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    if f.offset then
        if f.min then f.min = f.min + f.offset end
        if f.max then f.max = f.max + f.offset end
    end

    local minValue = inavsuite.app.utils.scaleValue(f.min, f)
    local maxValue = inavsuite.app.utils.scaleValue(f.max, f)

    if f.mult then
        if minValue then minValue = minValue * f.mult end
        if maxValue then maxValue = maxValue * f.mult end
    end

    minValue = minValue or 0
    maxValue = maxValue or 0

    formFields[i] = form.addSensorField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        function()
            if not (page.fields and page.fields[i]) then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(page.fields[i])
        end,
        function(value)
            if f.postEdit then f.postEdit(page) end
            if f.onChange then f.onChange(page) end
            f.value = inavsuite.app.utils.saveFieldValue(page.fields[i], value)
        end
    )

    local currentField = formFields[i]

    if f.onFocus  then currentField:onFocus(function() f.onFocus(page) end) end

    if f.disable  then currentField:enable(false)        end

end

-- Color field.
function ui.fieldColor(i)
    local app        = inavsuite.app
    local page       = app.Page
    local fields     = page.fields
    local f          = fields[i]
    local formLines  = app.formLines
    local formFields = app.formFields

    local posField, posText

    if f.inline and f.inline >= 1 and f.label then
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if f.t then
            if f.label then f.t = "        " .. f.t end
        else
            f.t = ""
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    if f.offset then
        if f.min then f.min = f.min + f.offset end
        if f.max then f.max = f.max + f.offset end
    end

    local minValue = inavsuite.app.utils.scaleValue(f.min, f)
    local maxValue = inavsuite.app.utils.scaleValue(f.max, f)

    if f.mult then
        if minValue then minValue = minValue * f.mult end
        if maxValue then maxValue = maxValue * f.mult end
    end

    minValue = minValue or 0
    maxValue = maxValue or 0

    formFields[i] = form.addColorField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        function()
            if not (page.fields and page.fields[i]) then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
            end
            local color = page.fields[i]
            if type(color) ~= "number" then
                return COLOR_BLACK
            else 
                return color
            end
        end,
        function(value)
            if f.postEdit then f.postEdit(page) end
            if f.onChange then f.onChange(page) end
            f.value = inavsuite.app.utils.saveFieldValue(page.fields[i], value)
        end
    )

    local currentField = formFields[i]

    if f.onFocus  then currentField:onFocus(function() f.onFocus(page) end) end

    if f.disable  then currentField:enable(false)        end

end

-- Source field.
function ui.fieldSwitch(i)
    local app        = inavsuite.app
    local page       = app.Page
    local fields     = page.fields
    local f          = fields[i]
    local formLines  = app.formLines
    local formFields = app.formFields

    local posField, posText

    if f.inline and f.inline >= 1 and f.label then
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if f.t then
            if f.label then f.t = "        " .. f.t end
        else
            f.t = ""
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    if f.offset then
        if f.min then f.min = f.min + f.offset end
        if f.max then f.max = f.max + f.offset end
    end

    local minValue = inavsuite.app.utils.scaleValue(f.min, f)
    local maxValue = inavsuite.app.utils.scaleValue(f.max, f)

    if f.mult then
        if minValue then minValue = minValue * f.mult end
        if maxValue then maxValue = maxValue * f.mult end
    end

    minValue = minValue or 0
    maxValue = maxValue or 0

    formFields[i] = form.addSwitchField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        function()
            if not (page.fields and page.fields[i]) then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(page.fields[i])
        end,
        function(value)
            if f.postEdit then f.postEdit(page) end
            if f.onChange then f.onChange(page) end
            f.value = inavsuite.app.utils.saveFieldValue(page.fields[i], value)
        end
    )

    local currentField = formFields[i]

    if f.onFocus  then currentField:onFocus(function() f.onFocus(page) end) end

    if f.disable  then currentField:enable(false)        end

end

-- Static text field.
function ui.fieldStaticText(i)
    local app         = inavsuite.app
    local page        = app.Page
    local fields      = page.fields
    local f           = fields[i]
    local formLines   = app.formLines
    local formFields  = app.formFields
    local radioText   = app.radio.text

    local posText, posField

    if f.inline and f.inline >= 1 and f.label then
        if radioText == 2 and f.t2 then f.t = f.t2 end
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if radioText == 2 and f.t2 then f.t = f.t2 end
        if f.t then
            if f.label then f.t = "        " .. f.t end
        else
            f.t = ""
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    -- if HideMe == true then ... end (kept as comment in original)

    formFields[i] = form.addStaticText(
        formLines[inavsuite.app.formLineCnt],
        posField,
        inavsuite.app.utils.getFieldValue(fields[i])
    )

    local currentField = formFields[i]
    if f.onFocus  then currentField:onFocus(function() f.onFocus(page) end) end
    if f.decimals then currentField:decimals(f.decimals) end
    if f.unit     then currentField:suffix(f.unit)       end
    if f.step     then currentField:step(f.step)         end
end

-- Text field.
function ui.fieldText(i)
    local app         = inavsuite.app
    local page        = app.Page
    local fields      = page.fields
    local f           = fields[i]
    local formLines   = app.formLines
    local formFields  = app.formFields
    local radioText   = app.radio.text

    local posText, posField

    if f.inline and f.inline >= 1 and f.label then
        if radioText == 2 and f.t2 then f.t = f.t2 end
        local p = inavsuite.app.utils.getInlinePositions(f, page)
        posText, posField = p.posText, p.posField
        form.addStaticText(formLines[inavsuite.app.formLineCnt], posText, f.t)
    else
        if radioText == 2 and f.t2 then f.t = f.t2 end
        if f.t then
            if f.label then f.t = "        " .. f.t end
        else
            f.t = ""
        end
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        formLines[inavsuite.app.formLineCnt] = form.addLine(f.t)
        posField = f.position or nil
    end

    formFields[i] = form.addTextField(
        formLines[inavsuite.app.formLineCnt],
        posField,
        function()
            if not fields or not fields[i] then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(fields[i])
        end,
        function(value)
            if f.postEdit then f.postEdit(page) end
            if f.onChange then f.onChange(page) end
            f.value = inavsuite.app.utils.saveFieldValue(fields[i], value)
        end
    )

    local currentField = formFields[i]
    if f.onFocus then currentField:onFocus(function() f.onFocus(page) end) end
    if f.disable then currentField:enable(false) end

    if f.help and app.fieldHelpTxt and app.fieldHelpTxt[f.help] and app.fieldHelpTxt[f.help].t then
        currentField:help(app.fieldHelpTxt[f.help].t)
    end

    if f.instantChange == false then
        currentField:enableInstantChange(false)
    else
        currentField:enableInstantChange(true)
    end
end

-- Label/header helper.
function ui.fieldLabel(f, i, l)
    local app = inavsuite.app

    if f.t then
        if f.t2    then f.t = f.t2 end
        if f.label then f.t = "        " .. f.t end
    end

    if f.label then
        local label      = app.ui.getLabel(f.label, l)
        local labelValue = label.t
        if label.t2 then labelValue = label.t2 end
        local labelName = f.t and labelValue or "unknown"

        if f.label ~= inavsuite.app.lastLabel then
            label.type = label.type or 0
            inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
            app.formLines[inavsuite.app.formLineCnt] = form.addLine(labelName)
            form.addStaticText(app.formLines[inavsuite.app.formLineCnt], nil, "")
            inavsuite.app.lastLabel = f.label
        end
    end
end

--------------------------------------------------------------------------------
-- Page header & navigation
--------------------------------------------------------------------------------

function ui.fieldHeader(title)
    local app       = inavsuite.app
    local radio     = app.radio
    local formFields = app.formFields
    local lcdWidth  = inavsuite.app.lcdWidth

    if not title then title = "No Title" end

    local w, _ = lcd.getWindowSize()
    local padding  = 5
    local colStart = math.floor(w * 59.4 / 100)
    if radio.navButtonOffset then colStart = colStart - radio.navButtonOffset end

    local buttonW = radio.buttonWidth and radio.menuButtonWidth or ((w - colStart) / 3 - padding)
    local buttonH = radio.navbuttonHeight

    formFields['menu'] =
        form.addLine("")

    formFields['title'] = form.addStaticText(
        formFields['menu'],
        { x = 0, y = radio.linePaddingTop, w = lcdWidth, h = radio.navbuttonHeight },
        title
    )

    app.ui.navigationButtons(w - 5, radio.linePaddingTop, buttonW, buttonH)
end

function ui.openPageRefresh(idx, title, script, extra1, extra2, extra3, extra5, extra6)
    inavsuite.app.triggers.isReady = false
end

--------------------------------------------------------------------------------
-- Help caching
--------------------------------------------------------------------------------

ui._helpCache = ui._helpCache or {}

local function getHelpData(section)
    if ui._helpCache[section] == nil then
        local helpPath = "app/modules/" .. section .. "/help.lua"
        if inavsuite.utils.file_exists(helpPath) then
            local ok, helpData = pcall(function()
                return assert(inavsuite.compiler.loadfile(helpPath))()
            end)
            ui._helpCache[section] = (ok and type(helpData) == "table") and helpData or false
        else
            ui._helpCache[section] = false
        end
    end
    return ui._helpCache[section] or nil
end

--------------------------------------------------------------------------------
-- Page opening
--------------------------------------------------------------------------------

function ui.openPage(idx, title, script, extra1, extra2, extra3, extra5, extra6)
    -- Global UI state; clear form data.
    inavsuite.app.uiState          = inavsuite.app.uiStatus.pages
    inavsuite.app.triggers.isReady = false
    inavsuite.app.formFields       = {}
    inavsuite.app.formLines        = {}
    inavsuite.app.lastLabel        = nil

    -- Load module.
    local modulePath = "app/modules/" .. script
    inavsuite.app.Page = assert(inavsuite.compiler.loadfile(modulePath))(idx)

    -- Load help (if present).
    local section  = script:match("([^/]+)")
    local helpData = getHelpData(section)
    inavsuite.app.fieldHelpTxt = helpData and helpData.fields or nil

    -- Module-specific openPage?
    if inavsuite.app.Page.openPage then
        inavsuite.app.Page.openPage(idx, title, script, extra1, extra2, extra3, extra5, extra6)
        inavsuite.utils.reportMemoryUsage(title)
        return
    end

    -- Fallback rendering.
    inavsuite.app.lastIdx   = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    form.clear()
    inavsuite.session.lastPage = script

    local pageTitle = inavsuite.app.Page.pageTitle or title
    inavsuite.app.ui.fieldHeader(pageTitle)

    if inavsuite.app.Page.headerLine then
        local headerLine = form.addLine("")
        form.addStaticText(headerLine, {
            x = 0, y = inavsuite.app.radio.linePaddingTop,
            w = inavsuite.app.lcdWidth, h = inavsuite.app.radio.navbuttonHeight
        }, inavsuite.app.Page.headerLine)
    end

    inavsuite.app.formLineCnt = 0

    inavsuite.utils.log("Merging form data from mspapi", "debug")
    inavsuite.app.Page.fields = inavsuite.app.Page.apidata.formdata.fields
    inavsuite.app.Page.labels = inavsuite.app.Page.apidata.formdata.labels

    if inavsuite.app.Page.fields then
        for i, field in ipairs(inavsuite.app.Page.fields) do
            local label   = inavsuite.app.Page.labels
            if inavsuite.session.apiVersion == nil then return end

            local valid =
                (field.apiversion    == nil or inavsuite.utils.apiVersionCompare(">=", field.apiversion))    and
                (field.apiversionlt  == nil or inavsuite.utils.apiVersionCompare("<",  field.apiversionlt))  and
                (field.apiversiongt  == nil or inavsuite.utils.apiVersionCompare(">",  field.apiversiongt))  and
                (field.apiversionlte == nil or inavsuite.utils.apiVersionCompare("<=", field.apiversionlte)) and
                (field.apiversiongte == nil or inavsuite.utils.apiVersionCompare(">=", field.apiversiongte)) and
                (field.enablefunction == nil or field.enablefunction())

            if field.hidden ~= true and valid then
                inavsuite.app.ui.fieldLabel(field, i, label)
                if     field.type == 0 then inavsuite.app.ui.fieldStaticText(i)
                elseif field.table or field.type == 1 then inavsuite.app.ui.fieldChoice(i)
                elseif field.type == 2 then inavsuite.app.ui.fieldNumber(i)
                elseif field.type == 3 then inavsuite.app.ui.fieldText(i)
                elseif field.type == 4 then inavsuite.app.ui.fieldBoolean(i)
                elseif field.type == 5 then inavsuite.app.ui.fieldBooleanInverted(i)  
                elseif field.type == 6 then inavsuite.app.ui.fieldSlider(i)  
                elseif field.type == 7 then inavsuite.app.ui.fieldSource(i)   
                elseif field.type == 8 then inavsuite.app.ui.fieldSwitch(i) 
                elseif field.type == 9 then inavsuite.app.ui.fieldSensor(i)     
                elseif field.type == 10 then inavsuite.app.ui.fieldColor(i) 
                else                         inavsuite.app.ui.fieldNumber(i)
                end
            else
                inavsuite.app.formFields[i] = {}
            end
        end
    end

    inavsuite.utils.reportMemoryUsage(title)
end

-- Navigation buttons (Menu / Save / Reload / Tool / Help).
function ui.navigationButtons(x, y, w, h)
    local xOffset    = 0
    local padding    = 5
    local wS         = w - (w * 20) / 100
    local helpOffset = 0
    local toolOffset = 0
    local reloadOffset = 0
    local saveOffset   = 0
    local menuOffset   = 0

    local navButtons
    if inavsuite.app.Page.navButtons == nil then
        navButtons = { menu = true, save = true, reload = true, help = true }
    else
        navButtons = inavsuite.app.Page.navButtons
    end

    -- Precompute offsets to keep focus order correct in Ethos.
    if navButtons.help   ~= nil and navButtons.help   == true then xOffset = xOffset + wS + padding end
    helpOffset = x - xOffset

    if navButtons.tool   ~= nil and navButtons.tool   == true then xOffset = xOffset + wS + padding end
    toolOffset = x - xOffset

    if navButtons.reload ~= nil and navButtons.reload == true then xOffset = xOffset + w + padding  end
    reloadOffset = x - xOffset

    if navButtons.save   ~= nil and navButtons.save   == true then xOffset = xOffset + w + padding  end
    saveOffset = x - xOffset

    if navButtons.menu   ~= nil and navButtons.menu   == true then xOffset = xOffset + w + padding  end
    menuOffset = x - xOffset

    -- MENU
    if navButtons.menu == true then
        inavsuite.app.formNavigationFields['menu'] = form.addButton(line, {
            x = menuOffset, y = y, w = w, h = h
        }, {
            text    = i18n("app.navigation_menu"),
            icon    = nil,
            options = FONT_S,
            paint   = function() end,
            press   = function()
                if inavsuite.app.Page and inavsuite.app.Page.onNavMenu then
                    inavsuite.app.Page.onNavMenu(inavsuite.app.Page)
                elseif inavsuite.app.lastMenu ~= nil then
                    inavsuite.app.ui.openMainMenuSub(inavsuite.app.lastMenu)
                else
                    inavsuite.app.ui.openMainMenu()
                end
            end
        })
        inavsuite.app.formNavigationFields['menu']:focus()
    end

    -- SAVE
    if navButtons.save == true then
        inavsuite.app.formNavigationFields['save'] = form.addButton(line, {
            x = saveOffset, y = y, w = w, h = h
        }, {
            text    = i18n("app.navigation_save"),
            icon    = nil,
            options = FONT_S,
            paint   = function() end,
            press   = function()
                if inavsuite.app.Page and inavsuite.app.Page.onSaveMenu then
                    inavsuite.app.Page.onSaveMenu(inavsuite.app.Page)
                else
                    inavsuite.app.triggers.triggerSave = true
                end
            end
        })
    end

    -- RELOAD
    if navButtons.reload == true then
        inavsuite.app.formNavigationFields['reload'] = form.addButton(line, {
            x = reloadOffset, y = y, w = w, h = h
        }, {
            text    = i18n("app.navigation_reload"),
            icon    = nil,
            options = FONT_S,
            paint   = function() end,
            press   = function()
                if inavsuite.app.Page and inavsuite.app.Page.onReloadMenu then
                    inavsuite.app.Page.onReloadMenu(inavsuite.app.Page)
                else
                    inavsuite.app.triggers.triggerReload = true
                end
                return true
            end
        })
    end

    -- TOOL
    if navButtons.tool == true then
        inavsuite.app.formNavigationFields['tool'] = form.addButton(line, {
            x = toolOffset, y = y, w = wS, h = h
        }, {
            text    = i18n("app.navigation_tools"),
            icon    = nil,
            options = FONT_S,
            paint   = function() end,
            press   = function()
                inavsuite.app.Page.onToolMenu()
            end
        })
    end

    -- HELP
    if navButtons.help == true then
        local section = inavsuite.app.lastScript:match("([^/]+)")
        local script  = inavsuite.app.lastScript:match("/([^/]+)%.lua$")

        local help = getHelpData(section)
        if help then
            inavsuite.app.formNavigationFields['help'] = form.addButton(line, {
                x = helpOffset, y = y, w = wS, h = h
            }, {
                text    = i18n("app.navigation_help"),
                icon    = nil,
                options = FONT_S,
                paint   = function() end,
                press   = function()
                    if inavsuite.app.Page and inavsuite.app.Page.onHelpMenu then
                        inavsuite.app.Page.onHelpMenu(inavsuite.app.Page)
                    else
                        if help.help[script] then
                            inavsuite.app.ui.openPageHelp(help.help[script], section)
                        else
                            inavsuite.app.ui.openPageHelp(help.help['default'], section)
                        end
                    end
                end
            })
        else
            inavsuite.app.formNavigationFields['help'] = form.addButton(line, {
                x = helpOffset, y = y, w = wS, h = h
            }, {
                text    = i18n("app.navigation_help"),
                icon    = nil,
                options = FONT_S,
                paint   = function() end,
                press   = function() end
            })
            inavsuite.app.formNavigationFields['help']:enable(false)
        end
    end
end

-- Open a help dialog with given text data.
function ui.openPageHelp(txtData, section)
    local message = table.concat(txtData, "\r\n\r\n")
    form.openDialog({
        width   = inavsuite.app.lcdWidth,
        title   = "Help - " .. inavsuite.app.lastTitle,
        message = message,
        buttons = { { label = i18n("app.btn_close"), action = function() return true end } },
        options = TEXT_LEFT
    })
end

--------------------------------------------------------------------------------
-- API attribute injection
--------------------------------------------------------------------------------

function ui.injectApiAttributes(formField, f, v)
    local utils = inavsuite.utils
    local log   = utils.log

    if v.decimals and not f.decimals then
        if f.type ~= 1 then
            log("Injecting decimals: " .. v.decimals, "debug")
            f.decimals = v.decimals
            if formField.decimals then
                formField:decimals(v.decimals)
            end
        end
    end

    if v.scale  and not f.scale  then log("Injecting scale: " .. v.scale,   "debug"); f.scale  = v.scale  end
    if v.mult   and not f.mult   then log("Injecting mult: " .. v.mult,     "debug"); f.mult   = v.mult   end
    if v.offset and not f.offset then log("Injecting offset: " .. v.offset, "debug"); f.offset = v.offset end

    if v.unit and not f.unit then
        if f.type ~= 1 then
            log("Injecting unit: " .. v.unit, "debug")
            if formField.suffix then
                formField:suffix(v.unit)
            end
        end
    end

    if v.step and not f.step then
        if f.type ~= 1 then
            log("Injecting step: " .. v.step, "debug")
            f.step = v.step
            if formField.step then
                formField:step(v.step)
            end
        end
    end

    if v.min and not f.min then
        f.min = v.min
        if f.offset then f.min = f.min + f.offset end
        if f.type ~= 1 then
            log("Injecting min: " .. f.min, "debug")
            if formField.minimum then
                formField:minimum(f.min)
            end
        end
    end

    if v.max and not f.max then
        f.max = v.max
        if f.offset then f.max = f.max + f.offset end
        if f.type ~= 1 then
            log("Injecting max: " .. f.max, "debug")
            if formField.maximum then
                formField:maximum(f.max)
            end
        end
    end

    if v.default and not f.default then
        f.default = v.default
        if f.offset then f.default = f.default + f.offset end
        local default = f.default * inavsuite.app.utils.decimalInc(f.decimals)
        if f.mult then default = default * f.mult end
        local str = tostring(default)
        if str:match("%.0$") then default = math.ceil(default) end
        if f.type ~= 1 then
            log("Injecting default: " .. default, "debug")
            if formField.default then
                formField:default(default)
            end
        end
    end

    if v.table and not f.table then
        f.table = v.table
        local idxInc = f.tableIdxInc or v.tableIdxInc
        local tbldata = inavsuite.app.utils.convertPageValueTable(v.table, idxInc)
        if f.type == 1 then
            log("Injecting table: {}", "debug")
            if formField.values then
                formField:values(tbldata)
            end
        end
    end

    if v.help then
        f.help = v.help
        log("Injecting help: {}", "debug")
        if formField.help then
            formField:help(v.help)
        end
    end

    -- Force focus to ensure field updates.
    if formField.focus then
        formField:focus(true)
    end
end

return ui
