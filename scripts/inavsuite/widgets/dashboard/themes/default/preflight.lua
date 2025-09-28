--[[
 * Copyright (C) Inav Project
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
 *
 * Note: Some icons have been sourced from https://www.flaticon.com/
]]--


local utils = inavsuite.widgets.dashboard.utils

local headeropts = utils.getHeaderOptions()
local colorMode = utils.themeColors()

-- Theme based configuration settings
local theme_section = "system/@default"

local THEME_DEFAULTS = {
    v_min = 18.0,
    v_max = 25.2,
}

-- User voltage min/max override support
local function getUserVoltageOverride(which)
  local prefs = inavsuite.session and inavsuite.session.modelPreferences
  if prefs and prefs["system/@default"] then
    local v = tonumber(prefs["system/@default"][which])
    -- Only use override if it is present and different from the default 6S values
    -- (Defaults: min=18.0, max=25.2)
    if which == "v_min" and v and math.abs(v - 18.0) > 0.05 then return v end
    if which == "v_max" and v and math.abs(v - 25.2) > 0.05 then return v end
  end
  return nil
end

local function getThemeValue(key)
    -- Use General preferences for TX values
    if key == "tx_min" or key == "tx_warn" or key == "tx_max" then
        if inavsuite and inavsuite.preferences and inavsuite.preferences.general then
            local val = inavsuite.preferences.general[key]
            if val ~= nil then return tonumber(val) end
        end
    end
    -- Theme defaults for other values
    if inavsuite and inavsuite.session and inavsuite.session.modelPreferences and inavsuite.session.modelPreferences[theme_section] then
        local val = inavsuite.session.modelPreferences[theme_section][key]
        val = tonumber(val)
        if val ~= nil then return val end
    end
    return THEME_DEFAULTS[key]
end

-- Theme Options based on screen width
local function getThemeOptionKey(W)
    if     W == 800 then return "ls_full"
    elseif W == 784 then return "ls_std"
    elseif W == 640 then return "ss_full"
    elseif W == 630 then return "ss_std"
    elseif W == 480 then return "ms_full"
    elseif W == 472 then return "ms_std"
    end
end

-- Theme Options based on screen width
local themeOptions = {
    -- Large screens - (X20 / X20RS / X18RS etc) Full/Standard
    ls_full = { 
        font = "FONT_XXL", 
        thickness = 60,
        valuepaddingtop = 45, 
        gaugepadding = 10
    },

    ls_std  = {
        font = "FONT_XXL", 
        thickness = 40,
        valuepaddingtop = 35, 
        gaugepadding = 10,
    },


    -- Medium screens (X18 / X18S / TWXLITE) - Full/Standard
    ms_full = { 
        font = "FONT_XXL",
        thickness = 40,
        valuepaddingtop = 35,
        gaugepadding = 10,
    },

    ms_std  = {
        font = "FONT_XXL", 
        thickness = 30,
        valuepaddingtop = 30, 
        gaugepadding = 0,
    },

    -- Small screens - (X14 / X14S) Full/Standard
    ss_full = {
        font = "FONT_XL", 
        thickness = 50,
        valuepaddingtop = 40,  
        gaugepadding = 5,
    },

    ss_std  = {
        font = "FONT_XL", 
        thickness = 40,
        valuepaddingtop = 35,  
        gaugepadding = 5,
    },
}

-- Caching for boxes
local lastScreenW = nil
local boxes_cache = nil
local header_boxes_cache = nil
local themeconfig = nil
local last_txbatt_type = nil

-- Theme Layout
local layout = {
    cols    = 20,
    rows    = 8,
    padding = 1,
    --showgrid = lcd.RGB(100, 100, 100)  -- or any color you prefer
}

-- Header Layout
local header_layout = utils.standardHeaderLayout(headeropts)

-- Header Boxes
local function header_boxes()
    local txbatt_type = 0
    if inavsuite and inavsuite.preferences and inavsuite.preferences.general then
        txbatt_type = inavsuite.preferences.general.txbatt_type or 0
    end

    -- Rebuild cache if type changed
    if header_boxes_cache == nil or last_txbatt_type ~= txbatt_type then
        header_boxes_cache = utils.standardHeaderBoxes(i18n, colorMode, headeropts, txbatt_type)
        last_txbatt_type = txbatt_type
    end
    return header_boxes_cache
end

-- Boxes
local function buildBoxes(W)
    
    -- Object based options determined by screensize
    local opts = themeOptions[getThemeOptionKey(W)] or themeOptions.unknown

return {
      {
        col     = 1,
        row     = 1,
        colspan = 8,
        rowspan = 4,
        type    = "image",
        subtype = "model",
        bgcolor = colorMode.bgcolor,
      },
      {
        col     = 1,
        row     = 5,
        colspan = 4,
        rowspan = 2,
        type    = "time",
        subtype = "flight",
        title   = "@i18n(widgets.dashboard.time):upper()@",
        titlepos= "bottom",
        titlecolor = colorMode.titlecolor,
        textcolor = colorMode.titlecolor,
        bgcolor = colorMode.bgcolor,
      },
      {
        col     = 5,
        row     = 5,
        colspan = 4,
        rowspan = 2,
        type    = "text",
        subtype = "telemetry",
        source  = "altitude",
        title   = "@i18n(widgets.dashboard.altitude):upper()@",
        titlepos= "bottom",
        decimals = 0,
        titlecolor = colorMode.titlecolor,
        textcolor = colorMode.titlecolor,
        bgcolor = colorMode.bgcolor,
      },
      {
        col     = 5,
        row     = 7,
        colspan = 2,
        rowspan = 2,
        type    = "time",
        subtype = "count",
        title   = "@i18n(widgets.dashboard.flights):upper()@",
        titlepos= "bottom",
        titlecolor = colorMode.titlecolor,
        textcolor = colorMode.titlecolor,
        bgcolor = colorMode.bgcolor,
      },      
      {
        col     = 1,
        row     = 7,
        colspan = 2,
        rowspan = 2,
        type    = "text",
        subtype = "telemetry",
        source  = "attroll",
        title   = "ATT ROLL",
        titlepos= "bottom",
        transform = "floor",
        titlecolor = colorMode.titlecolor,
        textcolor = colorMode.titlecolor,
        bgcolor = colorMode.bgcolor,
      },
      {
        col     = 3,
        row     = 7,
        colspan = 2,
        rowspan = 2,
        type    = "text",
        subtype = "telemetry",
        source  = "attpitch",
        title   = "ATT PITCH",
        titlepos= "bottom",
        transform = "floor",
        titlecolor = colorMode.titlecolor,
        textcolor = colorMode.titlecolor,
        bgcolor = colorMode.bgcolor,
      },

      {
        col     = 7,
        row     = 7,
        colspan = 2,
        rowspan = 2,
        type    = "text",
        subtype = "telemetry",
        source  = "link",
        unit    = "dB",
        title   = "@i18n(widgets.dashboard.lq):upper()@",
        titlepos= "bottom",
        transform = "floor",
        titlecolor = colorMode.titlecolor,
        textcolor = colorMode.titlecolor,
        bgcolor = colorMode.bgcolor,
      },
      {
        col     = 9,
        row     = 1,
        colspan = 12,
        rowspan = 8,
        type    = "navigation",
        subtype = "ah",
        bgcolor = colorMode.bgcolor,
      },
    }

end

local function boxes()
    local config = inavsuite and inavsuite.session and inavsuite.session.modelPreferences and inavsuite.session.modelPreferences[theme_section]
    local W = lcd.getWindowSize()
    if boxes_cache == nil or themeconfig ~= config or lastScreenW ~= W then
        boxes_cache = buildBoxes(W)
        themeconfig = config
        lastScreenW = W
    end
    return boxes_cache
end

return {
  layout = layout,
  boxes = boxes,
  header_boxes = header_boxes,
  header_layout = header_layout,
  scheduler = {
        spread_scheduling = false,         -- (optional: spread scheduling over the interval to avoid spikes in CPU usage) 
        spread_scheduling_paint = false,  -- optional: spread scheduling for paint (if true, paint will be spread over the interval) 
        spread_ratio = 0.5                -- optional: manually override default ratio logic (applies if spread_scheduling is true)
  }    
}
