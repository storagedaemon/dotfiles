local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local xrdb = xresources.get_current_theme()
local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()
local gears = require("gears")

-- inherit default theme
local theme = dofile(themes_path .. "default/theme.lua")

theme.font = "SF Pro Display Light 13"

theme.bg_normal = xrdb.background
theme.bg_focus = xrdb.color13
theme.bg_urgent = xrdb.color9
theme.bg_minimize = xrdb.color8
theme.bg_systray = theme.bg_normal

theme.fg_normal = xrdb.foreground
theme.fg_focus = theme.bg_normal
theme.fg_urgent = theme.bg_normal
theme.fg_minimize = theme.bg_normal

-- Borders
theme.useless_gap = dpi(5)
theme.border_width = dpi(3)
theme.border_normal = xrdb.color0
theme.border_focus = theme.bg_focus
theme.border_marked = xrdb.color10

-- Tasklist
theme.tasklist_fg_focus = theme.fg_normal
theme.tasklist_bg_focus = theme.bg_normal

-- Tooltips
theme.tooltip_fg = theme.fg_normal
theme.tooltip_bg = theme.bg_normal

-- Menu configuration
theme.menu_submenu_icon = themes_path .. "default/submenu.png"
theme.menu_height = dpi(16)
theme.menu_width = dpi(100)

-- Recolor Layout icons:
theme = theme_assets.recolor_layout(theme, theme.fg_normal)

-- Notification bounds
theme.notification_max_height = dpi(128)
theme.notification_max_width = dpi(512)
theme.notification_icon_size = dpi(128)
theme.notification_shape = function(cr, width, height)
    gears.shape.rounded_rect(cr, width, height, dpi(24))
end

-- Borrowed from @actionless, makes a color darker than before
local function darker(color_value, darker_n)
    local result = "#"
    for s in color_value:gmatch("[a-fA-F0-9][a-fA-F0-9]") do
        local bg_numeric_value = tonumber("0x" .. s) - darker_n
        if bg_numeric_value < 0 then
            bg_numeric_value = 0
        end
        if bg_numeric_value > 255 then
            bg_numeric_value = 255
        end
        result = result .. string.format("%2.2x", bg_numeric_value)
    end
    return result
end

-- Recolor titlebar icons, borrowed from @actionless
theme = theme_assets.recolor_titlebar(theme, theme.fg_normal, "normal")
theme = theme_assets.recolor_titlebar(theme, darker(theme.fg_normal, -60), "normal", "hover")
theme = theme_assets.recolor_titlebar(theme, xrdb.color1, "normal", "press")
theme = theme_assets.recolor_titlebar(theme, theme.fg_focus, "focus")
theme = theme_assets.recolor_titlebar(theme, darker(theme.fg_focus, -60), "focus", "hover")
theme = theme_assets.recolor_titlebar(theme, xrdb.color1, "focus", "press")

-- wibar configuration
theme.wibar_shape = gears.shape.rectangle
theme.wibar_width = "100%"
theme.wibar_height = dpi(32)
theme.wibar_border_width = 0
theme.wibar_border_color = xrdb.color6

-- wibar individual sub-bars
theme.wibar_subbar_margin = dpi(16) -- left and right padding for curved shape
theme.wibar_subbar_border_width = dpi(1)
theme.wibar_subbar_border_color = theme.bg_focus
theme.wibar_subbar_shape = function(cr, width, height)
    gears.shape.rounded_rect(cr, width, height, dpi(24))
end

-- Font for the tasklist specifically
theme.tasklist_font = "SF Pro Display 11"

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = "oomox-fairyfloss"

-- Generate taglist squares:
local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(taglist_square_size, theme.fg_normal)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(taglist_square_size, theme.fg_normal)

-- Wallpaper is handled by feh
theme.wallpaper = nil

-- Hide the systray by default because the systray is garbage
theme.hide_systray = true

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
