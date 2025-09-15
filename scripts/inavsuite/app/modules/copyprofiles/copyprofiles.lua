local labels = {}
local fields = {}

local i18n = inavsuite.i18n.get

fields[#fields + 1] = {t = i18n("app.modules.copyprofiles.profile_type"), value = 0, min = 0, max = 1, table = {[0] = i18n("app.modules.copyprofiles.profile_type_pid"), i18n("app.modules.copyprofiles.profile_type_rate")}}
fields[#fields + 1] = {t = i18n("app.modules.copyprofiles.source_profile"), value = 0, min = 0, max = 5, tableIdxInc = -1, table = {"1", "2", "3", "4", "5", "6"}}
fields[#fields + 1] = {t = i18n("app.modules.copyprofiles.dest_profile"), value = 0, min = 0, max = 5, tableIdxInc = -1, table = {"1", "2", "3", "4", "5", "6"}}

local doSave = false

local function onSaveMenu()
    local buttons = {{
        label = i18n("app.btn_ok"),
        action = function()

            --- trigger a write here
            doSave = true

            return true
        end
    }, {
        label = i18n("app.btn_cancel"),
        action = function()
            return true
        end
    }}
    local theTitle = i18n("app.modules.copyprofiles.msgbox_save")
    local theMsg
    if inavsuite.app.Page.extraMsgOnSave then
        theMsg = i18n("app.modules.copyprofiles.msgbox_msg") .. "\n\n" .. inavsuite.app.Page.extraMsgOnSave
    else    
        theMsg = i18n("app.modules.copyprofiles.msgbox_msg")
    end


    form.openDialog({
        width = nil,
        title = theTitle,
        message = theMsg,
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()
        end,
        options = TEXT_LEFT
    })
end    


local function getDestinationPidProfile(self)
    local destPidProfile
    if (self.currentPidProfile < self.maxPidProfiles - 1) then
        destPidProfile = self.currentPidProfile + 1
    else
        destPidProfile = self.currentPidProfile - 1
    end
    return destPidProfile
end

local function openPage(idx, title, script, extra1, extra2, extra3, extra5, extra6)
    -- Initialize global UI state and clear form data
    inavsuite.app.uiState = inavsuite.app.uiStatus.pages
    inavsuite.app.triggers.isReady = false
    inavsuite.app.formFields = {}
    inavsuite.app.formLines = {}


    -- Fallback behavior if no custom openPage exists
    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    form.clear()
    inavsuite.session.lastPage = script

    local pageTitle = inavsuite.app.Page.pageTitle or title
    inavsuite.app.ui.fieldHeader(pageTitle)

    if inavsuite.app.Page.headerLine then
        local headerLine = form.addLine("")
        form.addStaticText(headerLine, {
            x = 0,
            y = inavsuite.app.radio.linePaddingTop,
            w = app.lcdWidth,
            h = inavsuite.app.radio.navbuttonHeight
        }, inavsuite.app.Page.headerLine)
    end

    inavsuite.app.formLineCnt = 0

    if fields then
        for i, field in ipairs(fields) do
            local label = labels
            local version = inavsuite.session.apiVersion
            local valid = (field.apiversion    == nil or field.apiversion    <= version) and
                          (field.apiversionlt  == nil or field.apiversionlt  >  version) and
                          (field.apiversiongt  == nil or field.apiversiongt  <  version) and
                          (field.apiversionlte == nil or field.apiversionlte >= version) and
                          (field.apiversiongte == nil or field.apiversiongte <= version) and
                          (field.enablefunction == nil or field.enablefunction())

            if field.hidden ~= true and valid then
                inavsuite.app.ui.fieldLabel(field, i, label)
                if field.type == 0 then
                    inavsuite.app.ui.fieldStaticText(i)
                elseif field.table or field.type == 1 then
                    inavsuite.app.ui.fieldChoice(i)
                elseif field.type == 2 then
                    inavsuite.app.ui.fieldNumber(i)
                elseif field.type == 3 then
                    inavsuite.app.ui.fieldText(i)
                else
                    inavsuite.app.ui.fieldNumber(i)
                end
            else
                inavsuite.app.formFields[i] = {}
            end
        end
    end

    inavsuite.app.triggers.closeProgressLoader = true
end 

local function wakeup()
    if doSave == true then
        inavsuite.app.ui.progressDisplaySave()
        inavsuite.app.triggers.isSavingFake = true

        local payload = {}
        payload[1] = fields[1].value
        payload[2] = fields[3].value
        payload[3] = fields[2].value


        if payload[2] == payload[3] then
            inavsuite.utils.log("Source and destination profiles are the same. No need to copy.","info")
            doSave = false
        end

        local message = {
            command = 183, -- COPY PROFILE
            payload = payload,
            processReply = function(self, buf)
                inavsuite.app.triggers.closeProgressLoader = true
            end,
            simulatorResponse = {}
        }
        inavsuite.tasks.msp.mspQueue:add(message)


        doSave = false
    end     
end    

return {
    -- leaving this api as legacy for now due to unsual read/write scenario.
    -- to change it will mean a bit of a rewrite so leaving it for now.
    --write = 183, -- MSP_COPY_PROFILE
    reboot = false,
    eepromWrite = true,
    title = "Copy",
    openPage = openPage,
    wakeup = wakeup,
    onSaveMenu = onSaveMenu,
    labels = labels,
    fields = fields,
    getDestinationPidProfile = getDestinationPidProfile,
    API = {},
    navButtons = {
        menu = true,
        save = true,
        reload = false,
        tool = false,
        help = true
    },
}
