
local activateWakeup = false
local extraMsgOnSave = nil
local resetRates = false
local doFullReload = false
local i18n = inavsuite.i18n.get

if inavsuite.session.activeRateTable == nil then 
    inavsuite.session.activeRateTable = inavsuite.config.defaultRateProfile 
end

local rows
if inavsuite.utils.apiVersionCompare(">=", "12.08") then
    rows = {
        i18n("app.modules.rates_advanced.response_time"),
        i18n("app.modules.rates_advanced.acc_limit"),
        i18n("app.modules.rates_advanced.setpoint_boost_gain"),
        i18n("app.modules.rates_advanced.setpoint_boost_cutoff"),
        i18n("app.modules.rates_advanced.dyn_ceiling_gain"),
        i18n("app.modules.rates_advanced.dyn_deadband_gain"),
        i18n("app.modules.rates_advanced.dyn_deadband_filter"),
    }
else
    rows = {
        i18n("app.modules.rates_advanced.response_time"),
        i18n("app.modules.rates_advanced.acc_limit"),
    }
end

   
local apidata = {
    api = {
        [1] = 'RC_TUNING',
    },
    formdata = {
        name = i18n("app.modules.rates_advanced.dynamics"),
        labels = {
        },
        rows = rows,
        cols = {
            i18n("app.modules.rates_advanced.roll"),
            i18n("app.modules.rates_advanced.pitch"),
            i18n("app.modules.rates_advanced.yaw"),
            i18n("app.modules.rates_advanced.col")
        },
        fields = {
            -- response time
            {row = 1, col = 1, mspapi = 1, apikey = "response_time_1"},
            {row = 1, col = 2, mspapi = 1, apikey = "response_time_2"},
            {row = 1, col = 3, mspapi = 1, apikey = "response_time_3"},
            {row = 1, col = 4, mspapi = 1, apikey = "response_time_4"},

            {row = 2, col = 1, mspapi = 1, apikey = "accel_limit_1"},
            {row = 2, col = 2, mspapi = 1, apikey = "accel_limit_2"},
            {row = 2, col = 3, mspapi = 1, apikey = "accel_limit_3"},
            {row = 2, col = 4, mspapi = 1, apikey = "accel_limit_4"},

            {row = 3, col = 1, mspapi = 1, apikey = "setpoint_boost_gain_1", apiversiongte = 12.08},
            {row = 3, col = 2, mspapi = 1, apikey = "setpoint_boost_gain_2", apiversiongte = 12.08},
            {row = 3, col = 3, mspapi = 1, apikey = "setpoint_boost_gain_3", apiversiongte = 12.08},
            {row = 3, col = 4, mspapi = 1, apikey = "setpoint_boost_gain_4", apiversiongte = 12.08},
            
            {row = 4, col = 1, mspapi = 1, apikey = "setpoint_boost_cutoff_1", apiversiongte = 12.08},
            {row = 4, col = 2, mspapi = 1, apikey = "setpoint_boost_cutoff_2", apiversiongte = 12.08},
            {row = 4, col = 3, mspapi = 1, apikey = "setpoint_boost_cutoff_3", apiversiongte = 12.08},
            {row = 4, col = 4, mspapi = 1, apikey = "setpoint_boost_cutoff_4", apiversiongte = 12.08},

            {row = 5, col = 3, mspapi = 1, apikey = "yaw_dynamic_ceiling_gain", apiversiongte = 12.08},
            {row = 6, col = 3, mspapi = 1, apikey = "yaw_dynamic_deadband_gain", apiversiongte = 12.08},
            {row = 7, col = 3, mspapi = 1, apikey = "yaw_dynamic_deadband_filter", apiversiongte = 12.08},

        }
    }                 
}

function rightAlignText(width, text)
    local textWidth, _ = lcd.getTextSize(text)  -- Get the text width
    local padding = width - textWidth  -- Calculate how much padding is needed
    
    if padding > 0 then
        return string.rep(" ", math.floor(padding / lcd.getTextSize(" "))) .. text
    else
        return text  -- No padding needed if text is already wider than width
    end
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
        numCols = 4
    end
    local screenWidth = inavsuite.app.lcdWidth - 10
    local padding = 10
    local paddingTop = inavsuite.app.radio.linePaddingTop
    local h = inavsuite.app.radio.navbuttonHeight
    local w = ((screenWidth * 60 / 100) / numCols)
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

    inavsuite.session.colWidth = w - paddingRight

    local c = 1
    while loc > 0 do
        local colLabel = inavsuite.app.Page.cols[loc]

        positions[loc] = posX - w
        positions_r[c] = posX - w

        lcd.font(FONT_M)
        --local tsizeW, tsizeH = lcd.getTextSize(colLabel)
        colLabel = rightAlignText(inavsuite.session.colWidth, colLabel)

        local posTxt = positions_r[c] + paddingRight 

        pos = {x = posTxt, y = posY, w = w, h = h}
        inavsuite.app.formFields['col_'..tostring(c)] = form.addStaticText(line, pos, colLabel)

        posX = math.floor(posX - w)

        loc = loc - 1
        c = c + 1
    end

    -- display each row
    local fieldRows = {}
    for ri, rv in ipairs(inavsuite.app.Page.rows) do fieldRows[ri] = form.addLine(rv) end

    for i = 1, #inavsuite.app.Page.fields do
        local f = inavsuite.app.Page.fields[i]

        local valid =
            (f.apiversion    == nil or inavsuite.utils.apiVersionCompare(">=", f.apiversion))    and
            (f.apiversionlt  == nil or inavsuite.utils.apiVersionCompare("<",  f.apiversionlt))  and
            (f.apiversiongt  == nil or inavsuite.utils.apiVersionCompare(">",  f.apiversiongt))  and
            (f.apiversionlte == nil or inavsuite.utils.apiVersionCompare("<=", f.apiversionlte)) and
            (f.apiversiongte == nil or inavsuite.utils.apiVersionCompare(">=", f.apiversiongte)) and
            (f.enablefunction == nil or f.enablefunction())

        
        if f.row and f.col and valid then
            local l = inavsuite.app.Page.labels
            local pageIdx = i
            local currentField = i

            posX = positions[f.col]

            pos = {x = posX + padding, y = posY, w = w - padding, h = h}

            inavsuite.app.formFields[i] = form.addNumberField(fieldRows[f.row], pos, 0, 0, function()
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
    
end



local function postLoad(self)

    local v = apidata.values[apidata.api[1]].rates_type
    
    inavsuite.utils.log("Active Rate Table: " .. inavsuite.session.activeRateTable,"debug")

    if v ~= inavsuite.session.activeRateTable then
        inavsuite.utils.log("Switching Rate Table: " .. v,"info")
        inavsuite.app.triggers.reloadFull = true
        inavsuite.session.activeRateTable = v           
        return
    end 


    inavsuite.app.triggers.closeProgressLoader = true
    activateWakeup = true
end

local function wakeup()
    if activateWakeup and inavsuite.tasks.msp.mspQueue:isProcessed() then
        -- update active profile
        -- the check happens in postLoad          
        if inavsuite.session.activeRateProfile then
            inavsuite.app.formFields['title']:value(inavsuite.app.Page.title .. " #" .. inavsuite.session.activeRateProfile)
        end

        -- reload the page
        if doFullReload == true then
            inavsuite.utils.log("Reloading full after rate type change","info")
            inavsuite.app.triggers.reload = true
            doFullReload = false
        end    
    end
end

local function onToolMenu()
        
end



return {
    apidata = apidata,
    title = i18n("app.modules.rates_advanced.name"),
    reboot = false,
    openPage = openPage,
    eepromWrite = true,
    refreshOnRateChange = true,
    rTableName = rTableName,
    postLoad = postLoad,
    wakeup = wakeup,
    API = {},
    onToolMenu = onToolMenu,
    navButtons = {
        menu = true,
        save = true,
        reload = true,
        tool = false,
        help = true
    },
}
