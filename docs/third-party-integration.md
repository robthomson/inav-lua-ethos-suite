# 3rd Party widget hooks provided by inavsuite

This document explains the various hooks and APIs provided by **inavsuite** for developing widgets and extensions for Inav. It covers the lifecycle functions you can implement, how to register your widget, and how to leverage the inavsuite session, tasks, telemetry, MSP, and utility APIs.

---

## Table of Contents

1. [inavsuite APIs](#inavsuite-apis)
2. [Example Widget](#example-widget)
3. [License](#license)

## inavsuite APIs

inavsuite exposes several subsystems under the global `inavsuite` table.

### Session Data

* **Access**: `inavsuite.session` contains read-only session info.

  * `craftName`, `modelID`, `apiVersion`, `tailMode`, `swashMode`, `servoCount`, `governorMode`, etc.

```lua
local name = inavsuite.session.craftName or "-"
```

### Tasks API

* **Check active**: `inavsuite.tasks.active()` returns `true` when inavsuite is initialized.

### Telemetry API

* **Get sensor**: `inavsuite.tasks.telemetry.getSensorSource(id)` returns a sensor object.
* **Read value**: `:value()` to fetch the latest reading.

or a faster and more efficient:

* **Get sensor**: `inavsuite.tasks.telemetry.getSensor(id)` returns a value of the sensor


```lua
local rpmSensor = inavsuite.tasks.telemetry.getSensorSource("rpm")
local rpm = rpmSensor:value()
```

### MSP API

Use MSP to query the flight controller:

```lua
local API = inavsuite.tasks.msp.api.load("GOVERNOR_CONFIG")
API.setCompleteHandler(function(self, buf)
  local mode = API.readValue("gov_mode")
  -- process mode
end)
API.setUUID("550e8400-e29b-41d4-a716-446655440000")
API.read()
```

* **Queue check**: `inavsuite.tasks.msp.mspQueue:isProcessed()` to ensure no backlog.

### Utilities

* **Logging**: `inavsuite.utils.log(message, level)` where `level` is `"info"`, `"warn"`, or `"error"`.

```lua
inavsuite.utils.log("Headspeed: " .. rpm, "info")
```

## Example Widget

Below is a widget that logs session info and telemetry every 5 seconds, using the full example code:

```lua
--[[
 * Copyright (C) Inav Project
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * Note: Some icons have been sourced from https://www.flaticon.com/
 *
 * This script is a simple widget that shows how you can access various
 * session variables from Inav.
]]--

local environment = system.getVersion()
local lastPrintTime = 0
local printInterval = 5

local apiValue = nil

local function create()
    -- Create the widget
    local widget = {}
    return widget
end

local function configure(widget)
    -- Configure the widget (called by Ethos forms)
end

local function paint(widget)
    -- Paint the widget (on screen)
end

local function wakeup(widget)
    -- Handle the main loop
    local currentTime = os.clock()

    if currentTime - lastPrintTime >= printInterval then
        if inavsuite and inavsuite.tasks.active() then
            -- Log Inav session information
            inavsuite.utils.log("Craft Name: " .. (inavsuite.session.craftName or "-"), "info")
            inavsuite.utils.log("API Version: " .. (inavsuite.session.apiVersion or "-"), "info")
            inavsuite.utils.log("Tail Mode: " .. (inavsuite.session.tailMode or "-"), "info")
            inavsuite.utils.log("Swash Mode: " .. (inavsuite.session.swashMode or "-"), "info")
            inavsuite.utils.log("Servo Count: " .. (inavsuite.session.servoCount or "-"), "info")
            inavsuite.utils.log("Governor Mode: " .. (inavsuite.session.governorMode or "-"), "info")

            -- Read telemetry sensors
            local armflags = inavsuite.tasks.telemetry.getSensorSource("armflags")
            inavsuite.utils.log("Arm Flags: " .. (armflags:value() or "-"), "info")

            local rpm = inavsuite.tasks.telemetry.getSensorSource("rpm")
            inavsuite.utils.log("Headspeed: " .. (rpm:value() or "-"), "info")

            local voltage = inavsuite.tasks.telemetry.getSensorSource("voltage")
            inavsuite.utils.log("Voltage: " .. (voltage:value() or "-"), "info")

            -- MSP API - synchronous check example
            if apiValue == nil then
                local API = inavsuite.tasks.msp.api.load("GOVERNOR_CONFIG")
                API.setCompleteHandler(function(self, buf)
                    local governorMode = API.readValue("gov_mode")
                    inavsuite.utils.log("API Value: " .. governorMode, "info")
                    apiValue = governorMode
                end)
                API.setUUID("550e8400-e29b-41d4-a716-446655440000")
                API.read()
            else
                inavsuite.utils.log("API Value: " .. (apiValue or "-"), "info")
            end
        else
            inavsuite.utils.log("Init...", "info")
        end

        lastPrintTime = currentTime
    end
end

local function init()
    -- Register the widget
    local key = "rfgbss"
    local name = "Inav API Demo"

    system.registerWidget({
        key = key,
        name = name,
        create = create,
        configure = configure,
        paint = paint,
        wakeup = wakeup,
        read = read,
        write = write,
        event = event,
        menu = menu,
        persistent = false,
    })
end

return { init = init }
```

## License

This widget framework is licensed under GPLv3. See [LICENSE](https://www.gnu.org/licenses/gpl-3.0.en.html) for details.

This widget framework is licensed under GPLv3. See [LICENSE](https://www.gnu.org/licenses/gpl-3.0.en.html) for details.
