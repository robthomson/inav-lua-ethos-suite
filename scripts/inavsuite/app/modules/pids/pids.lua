local activateWakeup = false
local i18n = inavsuite.i18n.get
local apidata = {
    api = {
        [1] = 'PID_TUNING',
    },
    formdata = {
        labels = {
        },
        rows = {
            i18n("app.modules.pids.roll"),
            i18n("app.modules.pids.pitch"),
            i18n("app.modules.pids.yaw")
        },
        cols = {
            i18n("app.modules.pids.p"),
            i18n("app.modules.pids.i"),
            i18n("app.modules.pids.d"),
            i18n("app.modules.pids.f"),
            i18n("app.modules.pids.o"),
            i18n("app.modules.pids.b")
        },
        fields = {
            -- P
            {row = 1, col = 1, mspapi = 1, apikey = "pid_0_P"},
            {row = 2, col = 1, mspapi = 1, apikey = "pid_1_P"},
            {row = 3, col = 1, mspapi = 1, apikey = "pid_2_P"},
            {row = 1, col = 2, mspapi = 1, apikey = "pid_0_I"},
            {row = 2, col = 2, mspapi = 1, apikey = "pid_1_I"},
            {row = 3, col = 2, mspapi = 1, apikey = "pid_2_I"},
            {row = 1, col = 3, mspapi = 1, apikey = "pid_0_D"},
            {row = 2, col = 3, mspapi = 1, apikey = "pid_1_D"},
            {row = 3, col = 3, mspapi = 1, apikey = "pid_2_D"},
            {row = 1, col = 4, mspapi = 1, apikey = "pid_0_F"},
            {row = 2, col = 4, mspapi = 1, apikey = "pid_1_F"},
            {row = 3, col = 4, mspapi = 1, apikey = "pid_2_F"},
            {row = 1, col = 5, mspapi = 1, apikey = "pid_0_O"},
            {row = 2, col = 5, mspapi = 1, apikey = "pid_1_O"},
            {row = 1, col = 6, mspapi = 1, apikey = "pid_0_B"},
            {row = 2, col = 6, mspapi = 1, apikey = "pid_1_B"},
            {row = 3, col = 6, mspapi = 1, apikey = "pid_2_B"}
        }
    }                 
}


local function postLoad(self)
    inavsuite.app.triggers.closeProgressLoader = true
    activateWakeup = true
end

local function openPage(idx, title, script)

    inavsuite.app.uiState = inavsuite.app.uiStatus.pages
    inavsuite.app.triggers.isReady = false

    inavsuite.app.Page = assert(inavsuite.compiler.loadfile("app/modules/" .. script))()
    -- collectgarbage()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script
    inavsuite.session.lastPage = script

    inavsuite.app.uiState = inavsuite.app.uiStatus.pages

    longPage = false

    form.clear()

    inavsuite.app.ui.fieldHeader(title)
    local numCols
    if inavsuite.app.Page.cols ~= nil then
        numCols = #inavsuite.app.Page.cols
    else
        numCols = 6
    end
    local screenWidth = inavsuite.app.lcdWidth - 10
    local padding = 10
    local paddingTop = inavsuite.app.radio.linePaddingTop
    local h = inavsuite.app.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 20
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine("")

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop


    inavsuite.utils.log("Merging form data from mspapi","debug")
    inavsuite.app.Page.fields = inavsuite.app.Page.apidata.formdata.fields
    inavsuite.app.Page.labels = inavsuite.app.Page.apidata.formdata.labels
    inavsuite.app.Page.rows = inavsuite.app.Page.apidata.formdata.rows
    inavsuite.app.Page.cols = inavsuite.app.Page.apidata.formdata.cols

    local c = 1
    while loc > 0 do
        local colLabel = inavsuite.app.Page.cols[loc]
        pos = {x = posX, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)
        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)
        loc = loc - 1
        c = c + 1
    end

    -- display each row
    local pidRows = {}
    for ri, rv in ipairs(inavsuite.app.Page.rows) do pidRows[ri] = form.addLine(rv) end

    for i = 1, #inavsuite.app.Page.fields do
        local f = inavsuite.app.Page.fields[i]
        local l = inavsuite.app.Page.labels
        local pageIdx = i
        local currentField = i

        posX = positions[f.col]

        pos = {x = posX + padding, y = posY, w = w - padding, h = h}

        inavsuite.app.formFields[i] = form.addNumberField(pidRows[f.row], pos, 0, 0, function()
            if inavsuite.app.Page.fields == nil or inavsuite.app.Page.fields[i] == nil then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(inavsuite.app.Page.fields[i])
        end, function(value)
            if f.postEdit then f.postEdit(inavsuite.app.Page) end
            if f.onChange then f.onChange(inavsuite.app.Page) end
    
            f.value = inavsuite.app.utils.saveFieldValue(inavsuite.app.Page.fields[i], value)
        end)
    end
    
end

local function wakeup()

    if activateWakeup == true and inavsuite.tasks.msp.mspQueue:isProcessed() then

        -- update active profile
        -- the check happens in postLoad          
        if inavsuite.session.activeProfile ~= nil then
            inavsuite.app.formFields['title']:value(inavsuite.app.Page.title .. " #" .. inavsuite.session.activeProfile)
        end

    end

end

return {
    apidata = apidata,
    title = i18n("app.modules.pids.name"),
    reboot = false,
    eepromWrite = true,
    refreshOnProfileChange = true,
    postLoad = postLoad,
    openPage = openPage,
    wakeup = wakeup,
    API = {},
}
