-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Library for colors, shapes, objects
local gears = require("gears")
-- Window Management and window layout library
local awful = require("awful")
require("awful.autofocus")
-- Widget and widget layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- Lain widgets library and friends
local lain = require("lain")
local markup = lain.util.markup
-- Fancy help menu popup for buttons/keys definition
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify {
            preset = naughty.config.presets.critical,
            title = "Oops, there were errors during startup!",
            text = awesome.startup_errors
        }
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal(
        "debug::error",
        function(err)
            -- Make sure we don't go into an endless error loop
            if in_error then
                return
            end
            in_error = true

            naughty.notify {
                    preset = naughty.config.presets.critical,
                    title = "Oops, an error happened!",
                    text = tostring(err)
                }
            in_error = false
        end
    )
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("~/.config/awesome/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    --awful.layout.suit.max,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max.fullscreen
    -- awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Wibar

-- Create a textclock widget definition (repeated for each screen's wibox)
mytextclock = wibox.widget.textclock("%H:%M")
local mytextclock_tooltip = awful.tooltip {}
mytextclock_tooltip:add_to_object(mytextclock)
mytextclock:connect_signal("mouse::enter", function()
    mytextclock_tooltip.text = os.date("%A, %B %d")
end)

-- Button definitions for each taglist (repeated for each screen's wibox)
local taglist_buttons = gears.table.join(
    awful.button(
        {},
        1,
        function(t)
            t:view_only()
        end
    ),
    awful.button(
        {modkey},
        1,
        function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end
    ),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button(
        {modkey},
        3,
        function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end
    ),
    awful.button(
        {},
        5,
        function(t)
            awful.tag.viewnext(t.screen)
        end
    ),
    awful.button(
        {},
        4,
        function(t)
            awful.tag.viewprev(t.screen)
        end
    )
)

-- Enable scroll wheel against the top of the screen to change tag view
local top_of_screen_buttons = gears.table.join(
    awful.button(
        {},
        5,
        function(t)
            awful.tag.viewnext(t.screen)
        end
    ),
    awful.button(
        {},
        4,
        function(t)
            awful.tag.viewprev(t.screen)
        end
    )
)

-- Button definitions for each tasklist (repeated for each screen's wibox)
local tasklist_buttons = gears.table.join(
    awful.button(
        {},
        1,
        function(c)
            c:emit_signal("request::activate", "tasklist", {raise = true})
        end
    ),
    awful.button(
        {},
        4,
        function()
            awful.client.focus.byidx(1)
        end
    ),
    awful.button(
        {},
        5,
        function()
            awful.client.focus.byidx(-1)
        end
    )
)

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    else
        gears.wallpaper.set("#000000")
    end
end

-- Custom Filter for tasklist to only show tasks if there are at least
-- two clients among the currently visible tags on the current screen
local function filter_currenttags_more_than_one(c, screen)
    -- Only print client on the same screen as this widget
    if c.screen ~= screen then return false end
    -- Include sticky client too
    if c.sticky then return true end
    local tags = screen.selected_tags

    local active_client_count = 0;

    for _,tag in ipairs(tags) do
        local clients = tag:clients()
        for _,client in ipairs(clients) do
            active_client_count = active_client_count + 1
        end
    end

    if active_client_count < 2 then
        return false
    end

    for _, t in ipairs(tags) do
        local ctags = c:tags()
        for _, v in ipairs(ctags) do
            if v == t then
                return true
            end
        end
    end
    return false
end

-- Below, stuff for the wibar, but not screen-unique:

-- Battery, the emoji are reversed to look correct with text-based
-- emoji. Waxing when charging, waning when discharging.
battery_tooltip = awful.tooltip {}
local battery = lain.widget.bat({
    settings = function()
        local ac     = bat_now.status == "Charging"
        local perc   = tonumber(bat_now.perc)

        local symbol = ""
        if perc == nil then symbol = "☽"
        elseif perc >= 90 then symbol = "🌑︎"
        elseif perc >= 75 then symbol = ac and "🌘︎" or "🌒︎"
        elseif perc >= 55 then symbol = ac and "🌗︎" or "🌓︎"
        elseif perc >= 35 then symbol = ac and "🌖︎" or "🌔︎"
        else symbol = "🌕︎"
        end

        widget:set_markup(markup.fontfg(beautiful.font, beautiful.fg_normal, symbol))
        battery_tooltip:set_text(bat_now.perc .. "% (" .. bat_now.status .. ")")
    end
})
battery_tooltip:add_to_object(battery.widget)

-- Create simple separator widget
separator = wibox.widget.textbox(" ")

-- Wifi/Network
local wifi_icon = wibox.widget.textbox()
local wifi_tooltip = awful.tooltip {}
wifi_tooltip:add_to_object(wifi_icon)
local net = lain.widget.net {
    notify = "off",
    wifi_state = "on",
    settings = function()
        local wlan0 = net_now.devices.wlan0
        if wlan0 then
            if wlan0.wifi then
                local signal = wlan0.signal
                wifi_tooltip:set_text(tostring(signal))
                if signal < -83 then
                    wifi_icon:set_text("🜃")
                elseif signal < -70 then
                    wifi_icon:set_text("🜄")
                elseif signal < -53 then
                    wifi_icon:set_text("🜂")
                elseif signal >= -53 then
                    wifi_icon:set_text("🜁")
                end
            else
                wifi_icon:set_text("🝱")
            end
        end
    end
}

-- Redshift
local redshift = wibox.widget.textbox()
local redshift_tooltip = awful.tooltip {}
lain.widget.contrib.redshift.attach(
    redshift,
    function(active)
        if active then
            redshift:set_text("🝯")
            redshift_tooltip:set_text("Redshift is active")
        else
            redshift:set_text("☉")
            redshift_tooltip:set_text("Redshift is not active")
        end
    end
)
redshift_tooltip:add_to_object(redshift)

-- Set up unique per-screen widgets and
-- then draw the wibar for each screen
awful.screen.connect_for_each_screen(
    function(s)

        -- Wallpaper
        set_wallpaper(s)

        -- Each screen has its own tag table.
        awful.tag({
            " ☿ ",
            " ♀ ",
            " ♁ ",
            " ♂ ",
            " ♃ ",
            " ♄ ",
            " ♅ ",
            " ♆ ",
            -- " ♇ " -- planetn't
        }, s, awful.layout.layouts[1])

        -- Create a promptbox for each screen
        s.mypromptbox = awful.widget.prompt()

        -- Create an imagebox widget which will contain an icon indicating which layout we're using.
        -- We need one layoutbox per screen.
        s.mylayoutbox = awful.widget.layoutbox(s)
        s.mylayoutbox:buttons(
            gears.table.join(
                awful.button({}, 1, function() awful.layout.inc(1) end),
                awful.button({}, 3, function() awful.layout.inc(-1) end),
                awful.button({}, 5, function() awful.layout.inc(1) end),
                awful.button({}, 4, function() awful.layout.inc(-1) end)
            )
        )

        -- Create a taglist widget
        s.mytaglist = awful.widget.taglist {
            screen  = s,
            filter  = awful.widget.taglist.filter.all,
            buttons = taglist_buttons
        }

        -- Tasklist widget
        s.mytasklist = awful.widget.tasklist {
            screen  = s,
            filter  = awful.widget.tasklist.filter.focused,
            -- filter = awful.widget.tasklist.filter.currenttags,
            -- filter = filter_currenttags_more_than_one,
            buttons = tasklist_buttons,
            style   = {
                bg_normal = gears.color.transparent,
                bg_focus  = gears.color.transparent,
                font      = beautiful.tasklist_font,
                shape     = gears.shape.rounded_rect,
            },
            layout  = {
                spacing_widget = {
                    {
                        forced_width  = 5,
                        forced_height = 24,
                        thickness     = 1,
                        color         = beautiful.fg_normal,
                        widget        = wibox.widget.separator
                    },
                    valign = 'center',
                    halign = 'center',
                    widget = wibox.container.place,
                },
                spacing = 64,
                layout  = wibox.layout.fixed.horizontal
            },
            widget_template = {
                {
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    left   = 16,
                    right  = 15,
                    widget = wibox.container.margin
                },
                id     = 'background_role',
                widget = wibox.widget.background,
            },
        }

        -- Create a systray
        s.systray = wibox.widget.systray()
        s.systray.visible = not beautiful.hide_systray

        -- Finally create the wibar (wibox attached to the screen edge)
        s.mywibox = awful.wibar {
            position     = "top",
            bg           = gears.color.transparent,
            width        = beautiful.wibar_width,
            shape        = beautiful.wibar_shape,
            height       = beautiful.wibar_height + beautiful.useless_gap * 2,
            border_width = beautiful.wibar_border_width,
            screen       = s
        }

        -- Add widgets to the wibar
        s.mywibox:setup {
            {
                -- push the wibar away from the edge of the screen
                orientation   = "horizontal",
                thickness     = 0,
                forced_height = beautiful.useless_gap * 2,
                buttons       = top_of_screen_buttons,
                widget        = wibox.widget.separator
            },
            {
                layout = wibox.layout.align.horizontal,
                {
                    {
                        {
                            s.mytaglist,
                            left = beautiful.wibar_subbar_margin,
                            right = beautiful.wibar_subbar_margin,
                            widget = wibox.container.margin
                        },
                        bg                 = beautiful.bg_normal,
                        shape              = beautiful.wibar_subbar_shape,
                        shape_border_width = beautiful.wibar_subbar_border_width,
                        shape_border_color = beautiful.wibar_subbar_border_color,
                        widget             = wibox.container.background
                    },
                    left   = beautiful.useless_gap * 2,
                    right  = beautiful.useless_gap,
                    widget = wibox.container.margin
                },
                {
                    {
                        {
                            {
                                -- Middle widget, centered using separators
                                layout = wibox.layout.align.horizontal,
                                expand = "outside",
                                separator,
                                s.mytasklist,
                                separator,
                            },
                            left   = beautiful.wibar_subbar_margin,
                            right  = beautiful.wibar_subbar_margin,
                            widget = wibox.container.margin
                        },
                        bg                 = beautiful.bg_normal,
                        shape              = beautiful.wibar_subbar_shape,
                        shape_border_width = beautiful.wibar_subbar_border_width,
                        shape_border_color = beautiful.wibar_subbar_border_color,
                        widget             = wibox.container.background
                    },
                    left   = beautiful.useless_gap,
                    right  = beautiful.useless_gap,
                    widget = wibox.container.margin
                },
                {
                    {
                        {
                            {
                                -- Right widgets
                                layout = wibox.layout.fixed.horizontal,
                                {
                                    -- Add padding on the top and bottom of the systray
                                    -- to keep it from overlapping with the border
                                    s.systray,
                                    top    = 2,
                                    bottom = 2,
                                    widget = wibox.container.margin
                                },
                                separator,
                                redshift,
                                separator,
                                wifi_icon,
                                separator,
                                battery,
                                separator,
                                mytextclock,
                                separator,
                                {
                                    -- shrink the layout box a little, because reasons
                                    s.mylayoutbox,
                                    margins = 4,
                                    widget  = wibox.container.margin
                                },
                            },
                            left   = beautiful.wibar_subbar_margin,
                            right  = beautiful.wibar_subbar_margin,
                            widget = wibox.container.margin
                        },
                        bg                 = beautiful.bg_normal,
                        shape              = beautiful.wibar_subbar_shape,
                        shape_border_width = beautiful.wibar_subbar_border_width,
                        shape_border_color = beautiful.wibar_subbar_border_color,
                        widget             = wibox.container.background
                    },
                    left   = beautiful.useless_gap,
                    right  = beautiful.useless_gap * 2,
                    widget = wibox.container.margin
                },
            },
            widget = wibox.layout.align.vertical
        }
    end
) -- awful.screen.connect_for_each_screen
-- }}}

-- {{{ Mouse bindings for mousewheel on the wallpaper
root.buttons(gears.table.join(awful.button({}, 5, awful.tag.viewnext), awful.button({}, 4, awful.tag.viewprev)))
-- }}}

-- {{{ Global key bindings, valid everywhere
globalkeys = gears.table.join(
    awful.key({modkey}, "s", hotkeys_popup.show_help, {description = "show help", group = "awesome"}),
    awful.key({modkey}, "Left", awful.tag.viewprev, {description = "view previous", group = "tag"}),
    awful.key({modkey}, "Right", awful.tag.viewnext, {description = "view next", group = "tag"}),
    awful.key({modkey}, "Escape", awful.tag.history.restore, {description = "go back", group = "tag"}),
    awful.key(
        {modkey},
        "j",
        function()
            awful.client.focus.byidx(1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key(
        {modkey},
        "k",
        function()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    -- Layout manipulation
    awful.key(
        {modkey, "Shift"},
        "j",
        function()
            awful.client.swap.byidx(1)
        end,
        {description = "swap with next client by index", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "k",
        function()
            awful.client.swap.byidx(-1)
        end,
        {description = "swap with previous client by index", group = "client"}
    ),
    awful.key(
        {modkey, "Control"},
        "j",
        function()
            awful.screen.focus_relative(1)
        end,
        {description = "focus the next screen", group = "screen"}
    ),
    awful.key(
        {modkey, "Control"},
        "k",
        function()
            awful.screen.focus_relative(-1)
        end,
        {description = "focus the previous screen", group = "screen"}
    ),
    awful.key({modkey}, "u", awful.client.urgent.jumpto, {description = "jump to urgent client", group = "client"}),
    awful.key(
        {modkey},
        "Tab",
        function()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}
    ),
    awful.key(
        {modkey},
        "=",
        function()
            awful.screen.focused().systray.visible = not awful.screen.focused().systray.visible
        end,
        {description = "toggle systray visibility", group = "custom"}
    ),
    -- System keys
    awful.key(
        {},
        "XF86AudioRaiseVolume",
        function()
            awful.spawn("ponymix -d 0 increase 2")
        end
    ),
    awful.key(
        {},
        "XF86AudioLowerVolume",
        function()
            awful.spawn("ponymix -d 0 decrease 2")
        end
    ),
    awful.key(
        {},
        "XF86AudioMute",
        function()
            awful.spawn("ponymix -d 0 toggle")
        end
    ),
    -- Standard program
    awful.key(
        {modkey},
        "Return",
        function()
            awful.spawn(terminal)
        end,
        {description = "open a terminal", group = "launcher"}
    ),
    awful.key(
        {modkey},
        "space",
        function()
            awful.spawn("rofi -combi-modi window,drun -show combi -show-icons")
        end,
        {description = "show launcher", group = "launcher"}
    ),
    awful.key(
        {modkey, "Shift"},
        "a",
        function()
            awful.spawn("firefox")
        end,
        {description = "open a new browser window", group = "launcher"}
    ),
    awful.key(
        {modkey, "Shift"},
        "w",
        function()
            awful.spawn("mousepad")
        end,
        {description = "open a text editor", group = "launcher"}
    ),
    awful.key(
        {modkey, "Shift"},
        "s",
        function()
            awful.spawn("xfce4-screenshooter")
        end,
        {description = "take a screenshot", group = "launcher"}
    ),
    awful.key(
        {modkey, "Control"},
        "Return",
        function()
            awful.spawn("pcmanfm")
        end,
        {description = "open a file manager window", group = "launcher"}
    ),
    awful.key(
        {modkey, "Control"},
        "l",
        function()
            awful.spawn("betterlockscreen -l blur")
        end,
        {description = "lock the screen", group = "launcher"}
    ),
    awful.key({modkey, "Shift"}, "z", awesome.restart, {description = "reload awesome", group = "awesome"}),
    awful.key({modkey, "Shift"}, "x", awesome.quit, {description = "quit awesome", group = "awesome"}),
    awful.key(
        {modkey},
        "l",
        function()
            awful.tag.incmwfact(0.05)
        end,
        {description = "increase master width factor", group = "layout"}
    ),
    awful.key(
        {modkey},
        "h",
        function()
            awful.tag.incmwfact(-0.05)
        end,
        {description = "decrease master width factor", group = "layout"}
    ),
    awful.key(
        {modkey, "Shift"},
        "h",
        function()
            awful.tag.incnmaster(1, nil, true)
        end,
        {description = "increase the number of master clients", group = "layout"}
    ),
    awful.key(
        {modkey, "Shift"},
        "l",
        function()
            awful.tag.incnmaster(-1, nil, true)
        end,
        {description = "decrease the number of master clients", group = "layout"}
    ),
    awful.key(
        {modkey, "Control"},
        "h",
        function()
            awful.tag.incncol(1, nil, true)
        end,
        {description = "increase the number of columns", group = "layout"}
    ),
    awful.key(
        {modkey, "Control"},
        "l",
        function()
            awful.tag.incncol(-1, nil, true)
        end,
        {description = "decrease the number of columns", group = "layout"}
    ),
    awful.key(
        {modkey, "Shift"},
        "space",
        function()
            awful.layout.inc(1)
        end,
        {description = "select next", group = "layout"}
    ),
    awful.key(
        {modkey, "Shift"},
        "Tab",
        function()
            awful.layout.inc(-1)
        end,
        {description = "select previous", group = "layout"}
    ),
    awful.key(
        {modkey, "Control"},
        "n",
        function()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                c:emit_signal("request::activate", "key.unminimize", {raise = true})
            end
        end,
        {description = "restore minimized", group = "client"}
    )
)

-- These keyboard button action definitions are added
-- to each client via the "rules" section below.
clientkeys = gears.table.join(
    awful.key(
        {modkey},
        "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}
    ),
    awful.key(
        {modkey},
        "q",
        function(c)
            c:kill()
        end,
        {description = "close", group = "client"}
    ),
    awful.key(
        {modkey, "Control"},
        "space",
        awful.client.floating.toggle,
        {description = "toggle floating", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "Return",
        function(c)
            c:swap(awful.client.getmaster())
        end,
        {description = "move to master", group = "client"}
    ),
    awful.key(
        {modkey},
        "o",
        function(c)
            c:move_to_screen()
        end,
        {description = "move to screen", group = "client"}
    ),
    awful.key(
        {modkey},
        "t",
        function(c)
            c.ontop = not c.ontop
        end,
        {description = "toggle keep on top", group = "client"}
    ),
    awful.key(
        {modkey},
        "n",
        function(c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        {description = "minimize", group = "client"}
    ),
    awful.key(
        {modkey},
        "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        {description = "(un)maximize", group = "client"}
    ),
    awful.key(
        {modkey, "Control"},
        "m",
        function(c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end,
        {description = "(un)maximize vertically", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end,
        {description = "(un)maximize horizontally", group = "client"}
    )
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(
        globalkeys,
        -- View tag only.
        awful.key(
            {modkey},
            "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            {description = "view tag #" .. i, group = "tag"}
        ),
        -- Toggle tag display.
        awful.key(
            {modkey, "Control"},
            "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            {description = "toggle tag #" .. i, group = "tag"}
        ),
        -- Move client to tag.
        awful.key(
            {modkey, "Shift"},
            "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            {description = "move focused client to tag #" .. i, group = "tag"}
        ),
        -- Toggle tag on focused client.
        awful.key(
            {modkey, "Control", "Shift"},
            "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            {description = "toggle focused client on tag #" .. i, group = "tag"}
        )
    )
end

-- These mouse click action definitions are added
-- to each client via the "rules" section below.
clientbuttons = gears.table.join(
    awful.button(
        {},
        1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
        end
    ),
    awful.button(
        {modkey},
        1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.move(c)
        end
    ),
    awful.button(
        {modkey,"Shift"},
        1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.resize(c)
        end
    ),
    awful.button(
        {modkey},
        3,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.resize(c)
        end
    )
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    },
    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA",  -- Firefox addon DownThemAll.
                "copyq",  -- Includes session name in class.
                "pinentry",
            },
            class = {
                "Arandr",
                "Blueman-manager",
                "Gpick",
                "Sxiv",
                "Wpa_gui",
                "xtightvncviewer"
            },

            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
                "Event Tester",  -- xev.
            },
            role = {
                "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        callback = function(c)
            awful.placement.centered(c,nil)
        end,
        properties = { floating = true }
    },
    -- on-screen keyboard
    {
        rule = { class = "Onboard" },
        properties = {
            floating = true,
            focusable = false
        }
    },
    {
        rule_any = { type = "dialog" },
        properties = { titlebars_enabled = true },
        callback = function(c)
            awful.placement.centered(c,nil)
        end
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)

client.connect_signal("property::urgent", function(c)
    c.minimized = false
    c:jump_to()
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c): setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            --awful.titlebar.widget.maximizedbutton(c),
            --awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Set up signals so libinput-gestures can switch tags via awesome-client
awesome.connect_signal("tag::next", function(args) awful.tag.viewnext() end)
awesome.connect_signal("tag::prev", function(args) awful.tag.viewprev() end)

-- }}}

-- {{{ systemd
-- Using systemd's user daemon to manage autostart of applications

-- Garbage for the garbage pile (systray)
awful.spawn("systemctl --user start nm-applet", false)
awful.spawn("systemctl --user start blueman-applet", false)

-- Background services
awful.spawn("systemctl --user start picom", false)
awful.spawn("systemctl --user start libinput-gestures", false)

-- One-shot run, every time Awesome restarts
awful.spawn("systemctl --user restart feh", false)

-- }}}
