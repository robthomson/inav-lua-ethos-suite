local labels = {}
local tables = {}

local activateWakeup = false
local i18n = inavsuite.i18n.get

tables[0] = "app/modules/rates/ratetables/none.lua"
tables[1] = "app/modules/rates/ratetables/betaflight.lua"
tables[2] = "app/modules/rates/ratetables/raceflight.lua"
tables[3] = "app/modules/rates/ratetables/kiss.lua"
tables[4] = "app/modules/rates/ratetables/actual.lua"
tables[5] = "app/modules/rates/ratetables/quick.lua"

if inavsuite.session.activeRateTable == nil then 
    inavsuite.session.activeRateTable = inavsuite.config.defaultRateProfile 
end


inavsuite.utils.log("Loading Rate Table: " .. tables[inavsuite.session.activeRateTable],"debug")
local apidata = assert(inavsuite.compiler.loadfile(tables[inavsuite.session.activeRateTable]))()
local mytable = apidata.formdata



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

    inavsuite.app.Page = assert(inavsuite.compiler.loadfile("app/modules/" .. script))()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script
    inavsuite.session.lastPage = script

    inavsuite.app.uiState = inavsuite.app.uiStatus.pages

    longPage = false

    form.clear()

    inavsuite.app.ui.fieldHeader(title)

    inavsuite.utils.log("Merging form data from apidata","debug")
    inavsuite.app.Page.fields = inavsuite.app.Page.apidata.formdata.fields
    inavsuite.app.Page.labels = inavsuite.app.Page.apidata.formdata.labels
    inavsuite.app.Page.rows = inavsuite.app.Page.apidata.formdata.rows
    inavsuite.app.Page.cols = inavsuite.app.Page.apidata.formdata.cols

    local numCols
    if inavsuite.app.Page.cols ~= nil then
        numCols = #inavsuite.app.Page.cols
    else
        numCols = 3
    end

    -- we dont use the global due to scrollers
    local screenWidth, screenHeight = lcd.getWindowSize()

    local padding = 10
    local paddingTop = inavsuite.app.radio.linePaddingTop
    local h = inavsuite.app.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 10
    local positions = {}
    local positions_r = {}
    local pos

    --line = form.addLine(apidata.formdata.name)
    line = form.addLine("")
    pos = {x = 0, y = paddingTop, w = 200, h = h}
    inavsuite.app.formFields['col_0'] = form.addStaticText(line, pos, apidata.formdata.name)

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

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
    local rateRows = {}
    for ri, rv in ipairs(inavsuite.app.Page.rows) do rateRows[ri] = form.addLine(rv) end

    for i = 1, #inavsuite.app.Page.fields do
        local f = inavsuite.app.Page.fields[i]
        local l = inavsuite.app.Page.labels
        local pageIdx = i
        local currentField = i

        if f.hidden == nil or f.hidden == false then
            posX = positions[f.col]

            pos = {x = posX + padding, y = posY, w = w - padding, h = h}

            minValue = f.min * inavsuite.app.utils.decimalInc(f.decimals)
            maxValue = f.max * inavsuite.app.utils.decimalInc(f.decimals)
            if f.mult ~= nil then
                minValue = minValue * f.mult
                maxValue = maxValue * f.mult
            end
            if f.scale ~= nil then
                minValue = minValue / f.scale
                maxValue = maxValue / f.scale
            end            

            inavsuite.app.formFields[i] = form.addNumberField(rateRows[f.row], pos, minValue, maxValue, function()
                local value
                if inavsuite.session.activeRateProfile == 0 then
                    value = 0
                else
                    value = inavsuite.app.utils.getFieldValue(inavsuite.app.Page.fields[i])
                end
                return value
            end, function(value)
                f.value = inavsuite.app.utils.saveFieldValue(inavsuite.app.Page.fields[i], value)
            end)
            if f.default ~= nil then
                local default = f.default * inavsuite.app.utils.decimalInc(f.decimals)
                if f.mult ~= nil then default = math.floor(default * f.mult) end
                if f.scale ~= nil then default = math.floor(default / f.scale) end
                inavsuite.app.formFields[i]:default(default)
            else
                inavsuite.app.formFields[i]:default(0)
            end           
            if f.decimals ~= nil then inavsuite.app.formFields[i]:decimals(f.decimals) end
            if f.unit ~= nil then inavsuite.app.formFields[i]:suffix(f.unit) end
            if f.step ~= nil then inavsuite.app.formFields[i]:step(f.step) end
            if f.help ~= nil then
                if inavsuite.app.fieldHelpTxt[f.help]['t'] ~= nil then
                    local helpTxt = inavsuite.app.fieldHelpTxt[f.help]['t']
                    inavsuite.app.formFields[i]:help(helpTxt)
                end
            end   
            if f.disable == true then 
                inavsuite.app.formFields[i]:enable(false) 
            end  
        end
    end

end

local function wakeup()

    if activateWakeup == true and inavsuite.tasks.msp.mspQueue:isProcessed() then       
        if inavsuite.session.activeRateProfile ~= nil then
            if inavsuite.app.formFields['title'] then
                inavsuite.app.formFields['title']:value(inavsuite.app.Page.title .. " #" .. inavsuite.session.activeRateProfile)
            end
        end 
    end
end

local function onHelpMenu()

    local helpPath = "app/modules/rates/help.lua"
    local help = assert(inavsuite.compiler.loadfile(helpPath))()

    inavsuite.app.ui.openPageHelp(help.help["table"][inavsuite.session.activeRateTable], "rates")


end    

return {
    apidata = apidata,
    title = i18n("app.modules.rates.name"),
    reboot = false,
    eepromWrite = true,
    refreshOnRateChange = true,
    rows = mytable.rows,
    cols = mytable.cols,
    flagRateChange = flagRateChange,
    postLoad = postLoad,
    openPage = openPage,
    wakeup = wakeup,
    onHelpMenu = onHelpMenu,
    API = {},
}
