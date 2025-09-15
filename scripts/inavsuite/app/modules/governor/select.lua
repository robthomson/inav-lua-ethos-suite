local function openPage(pidx, title, script)

    if inavsuite.utils.apiVersionCompare(">=", "12.09") then
        -- load new menu with 3 pages
        inavsuite.app.ui.openPage(pidx, title, "governor/governor.lua")        
    else
        -- load legacy single page rf2.2
        inavsuite.app.ui.openPage(pidx, title, "governor/governor_legacy.lua")
    end

end

return {
    pages = nil, 
    openPage = openPage,
    event = nil,
    wakeup = nil,  
}