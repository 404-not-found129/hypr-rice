-- ─────────────────────────────────────────────────────────
--  Hyprland (Lua config) — hypr-rice (colors follow the active Aether theme)
-- ─────────────────────────────────────────────────────────

------------------
---- MONITORS ----
------------------

-- Native resolution at the highest refresh rate on every monitor
hl.monitor({
    output   = "",
    mode     = "highrr",
    position = "auto",
    scale    = 1,
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "alacritty"
local fileManager = "thunar"
local menu        = "walker"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- let systemd user units (theme-schedule.timer) talk to this session
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP DISPLAY")
    hl.exec_cmd("waybar")
    hl.exec_cmd("systemctl --user reset-failed swaync xdg-desktop-portal-hyprland 2>/dev/null; systemctl --user start swaync")
    hl.exec_cmd("elephant")
    hl.exec_cmd("sleep 0.5 && walker --gapplication-service")
    hl.exec_cmd("sleep 1 && ~/.local/bin/theme-picker --service")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && wp=$(ls -t ~/.config/aether/theme/backgrounds/* 2>/dev/null | head -n1); [ -n \"$wp\" ] && ln -sf \"$wp\" ~/Pictures/wallpapers/wall.png; awww img ~/Pictures/wallpapers/wall.png --transition-type grow --transition-pos center")
    hl.exec_cmd("sleep 2 && ~/.local/bin/livewall sync")  -- live wallpaper, if on
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("~/.local/bin/color-scheme-sync")  -- light/dark follows the active theme
    -- icon theme is managed per-theme by game-icons (persists via dconf)
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Aether-Cursor")  -- stable symlink, swapped per theme
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Border colors follow Aether's wallpaper palette (fallback: Catppuccin Mocha)
local function aether_color(key, fallback)
    local ok, f = pcall(io.open, os.getenv("HOME") .. "/.config/aether/theme/colors.toml", "r")
    if not ok or not f then return fallback end
    local hex = fallback
    for line in f:lines() do
        local v = line:match("^" .. key .. '%s*=%s*"#(%x+)"')
        if v then hex = v; break end
    end
    f:close()
    return hex
end

-- Look & feel knobs, overridable from the settings app (rice-settings),
-- which writes ~/.config/hypr-rice/look.lua as a plain Lua table.
local look = {
    gaps_in          = 5,
    gaps_out         = 12,
    border_size      = 2,
    rounding         = 12,
    blur             = true,
    animations       = true,
    inactive_opacity = 0.95,
    terminal_opacity = 0.72,
    shadows          = true,
    workspaces_per_monitor = 3,
    follow_mouse     = true,
    sensitivity      = 0,     -- -1.0 .. 1.0
    square_corners   = false, -- windows (and, via the settings app, the bar)
    bar_position     = "top", -- applied to waybar by the settings app
}
do
    local ok, user = pcall(dofile, os.getenv("HOME") .. "/.config/hypr-rice/look.lua")
    if ok and type(user) == "table" then
        for k, v in pairs(user) do look[k] = v end
    end
end

local accent        = aether_color("accent",   "cba6f7")
local accent2       = aether_color("cursor",   "89b4fa")
local border_muted  = aether_color("muted",    "313244")

hl.config({
    general = {
        gaps_in  = look.gaps_in,
        gaps_out = look.gaps_out,

        border_size = look.border_size,

        col = {
            active_border   = { colors = { "rgba(" .. accent .. "ff)", "rgba(" .. accent2 .. "ff)" }, angle = 45 },
            inactive_border = "rgba(" .. border_muted .. "ff)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = look.square_corners and 0 or look.rounding,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = look.inactive_opacity,

        shadow = {
            enabled      = look.shadows,
            range        = 20,
            render_power = 3,
            color        = 0xcc1a1a2e,
        },

        blur = {
            enabled  = look.blur,
            size     = 8,
            passes   = 4,

            -- glassier look
            noise              = 0.012,
            contrast           = 0.9,
            brightness         = 1.05,
            vibrancy           = 0.25,
            vibrancy_darkness  = 0.5,

            -- full-strength blur behind translucent windows
            ignore_opacity = true,

            popups  = true,
            special = true,
        },
    },

    animations = {
        enabled = look.animations,
    },
})

-- Curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- Animations (smooth spring windows, gentle fades)
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        focus_on_activate       = true,
        vrr                     = 1,
    },
})

-- Uncomment if the cursor glitches or disappears (older NVIDIA issue):
-- hl.config({ cursor = { no_hardware_cursors = true } })

-- Custom cursor themes (like EldenRingCursor) are plain Xcursor, not
-- hyprcursor format. Without this, Hyprland looks for a hyprcursor theme
-- of that name, finds none, and silently keeps the previous cursor.
hl.config({ cursor = { enable_hyprcursor = false } })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "us",

        follow_mouse  = look.follow_mouse and 1 or 0,
        sensitivity   = look.sensitivity,
        accel_profile = "flat",

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- 3-finger swipe to change workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


---------------------
---- KEYBINDINGS ----
---------------------

-- Every bind has a description, which is also its stable id. The settings
-- app (Keybinds page) saves your changes to ~/.config/hypr-rice/binds.lua:
--   return {
--     keys     = { ["close window"] = "SUPER + W" },   -- new keys, by description
--     disabled = { ["pseudo-tile"] = true },
--     apps     = { { keys = "SUPER + B", name = "Firefox", cmd = "gtk-launch firefox" } },
--   }
local user_binds = { keys = {}, disabled = {}, apps = {} }
do
    local ok, t = pcall(dofile, os.getenv("HOME") .. "/.config/hypr-rice/binds.lua")
    if ok and type(t) == "table" then
        for k, v in pairs(t) do user_binds[k] = v end
    end
end

-- description -> dispatcher, so the cheat sheet can run any bind:
--   hyprctl dispatch 'rice_binds["random theme"]'
_G.rice_binds = {}

local function bind(keys, description, dispatcher, opts)
    if user_binds.disabled[description] then return end
    opts = opts or {}
    opts.description = description
    _G.rice_binds[description] = dispatcher
    hl.bind(user_binds.keys[description] or keys, dispatcher, opts)
end

local mainMod = "SUPER"
local bin = "~/.local/bin/"

-- Apps
bind(mainMod .. " + Return", "terminal",     hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + E",      "file manager", hl.dsp.exec_cmd(fileManager))
bind(mainMod .. " + Space",  "app launcher", hl.dsp.exec_cmd(menu))

-- Window management
bind(mainMod .. " + Q", "close window",      hl.dsp.window.close())
bind(mainMod .. " + V", "toggle floating",   hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + P", "pseudo-tile",       hl.dsp.window.pseudo())
bind(mainMod .. " + J", "toggle split",      hl.dsp.layout("togglesplit"))
bind(mainMod .. " + F", "fullscreen",        hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind(mainMod .. " + M", "maximize",          hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))

-- Session
bind(mainMod .. " + L",      "lock screen",  hl.dsp.exec_cmd("loginctl lock-session"))  -- via hypridle's lock_cmd
bind(mainMod .. " + Escape", "power menu",   hl.dsp.exec_cmd("wlogout"))

-- Utilities
bind(mainMod .. " + SHIFT + C", "color picker",       hl.dsp.exec_cmd("hyprpicker -a"))
bind(mainMod .. " + SHIFT + V", "clipboard history",  hl.dsp.exec_cmd("walker -m clipboard"))
bind(mainMod .. " + SHIFT + N", "notification center", hl.dsp.exec_cmd("swaync-client -t -sw"))
bind(mainMod .. " + period",    "emoji / symbol picker", hl.dsp.exec_cmd("walker -m symbols"))

-- Screenshots (saved to ~/Pictures/screenshots + clipboard) and recording
bind("Print",         "screenshot region", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/screenshots"))
bind("SHIFT + Print", "screenshot window", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures/screenshots"))
bind("CTRL + Print",  "screenshot screen", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/screenshots"))
bind(mainMod .. " + SHIFT + R", "record region (again to stop)", hl.dsp.exec_cmd(bin .. "screenrec region"))
bind(mainMod .. " + ALT + R",   "record screen (again to stop)", hl.dsp.exec_cmd(bin .. "screenrec screen"))

-- Themes and wallpapers (see `themectl`)
bind(mainMod .. " + T",         "theme picker",                 hl.dsp.exec_cmd(bin .. "theme-picker"))
bind(mainMod .. " + SHIFT + T", "random theme",                 hl.dsp.exec_cmd(bin .. "themectl random"))
bind(mainMod .. " + CTRL + T",  "theme from current wallpaper", hl.dsp.exec_cmd(bin .. "themectl auto"))
bind(mainMod .. " + right",     "next wallpaper",               hl.dsp.exec_cmd(bin .. "wallcycle next"))
bind(mainMod .. " + left",      "previous wallpaper",           hl.dsp.exec_cmd(bin .. "wallcycle prev"))
bind(mainMod .. " + SHIFT + W", "random wallpaper",             hl.dsp.exec_cmd(bin .. "wallcycle random"))
bind(mainMod .. " + ALT + W",   "live wallpaper on/off",        hl.dsp.exec_cmd(bin .. "livewall toggle"))

-- Extras
bind(mainMod .. " + slash", "keybind cheat sheet", hl.dsp.exec_cmd(bin .. "keybinds"))
bind(mainMod .. " + comma", "settings",            hl.dsp.exec_cmd(bin .. "rice-settings"))
bind(mainMod .. " + N",     "night light",         hl.dsp.exec_cmd(bin .. "nightlight toggle"))

-- Focus / move / resize
bind(mainMod .. " + ALT + left",  "focus left",  hl.dsp.focus({ direction = "left" }))
bind(mainMod .. " + ALT + right", "focus right", hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + up",          "focus up",    hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + down",        "focus down",  hl.dsp.focus({ direction = "down" }))

bind(mainMod .. " + SHIFT + left",  "move window left",  hl.dsp.window.move({ direction = "l" }))
bind(mainMod .. " + SHIFT + right", "move window right", hl.dsp.window.move({ direction = "r" }))
bind(mainMod .. " + SHIFT + up",    "move window up",    hl.dsp.window.move({ direction = "u" }))
bind(mainMod .. " + SHIFT + down",  "move window down",  hl.dsp.window.move({ direction = "d" }))

bind(mainMod .. " + CTRL + left",  "shrink width",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
bind(mainMod .. " + CTRL + right", "grow width",    hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
bind(mainMod .. " + CTRL + up",    "shrink height", hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
bind(mainMod .. " + CTRL + down",  "grow height",   hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

bind(mainMod .. " + mouse:272", "drag window",          hl.dsp.window.drag(),   { mouse = true })
bind(mainMod .. " + mouse:273", "resize window (mouse)", hl.dsp.window.resize(), { mouse = true })

-- Desktops: every monitor gets its own set (look.workspaces_per_monitor,
-- default 3), numbered left to right: the leftmost monitor has 1-3, the
-- next 4-6, and so on. SUPER + 1/2/3 always means "desktop 1/2/3 of the
-- monitor you're on".
local WS = look.workspaces_per_monitor

local function monitors_ordered()
    local ms = hl.get_monitors() or {}
    table.sort(ms, function(a, b)
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    return ms
end

local function ws_base(name)
    for i, m in ipairs(monitors_ordered()) do
        if m.name == name then return (i - 1) * WS end
    end
    return 0
end

local function place_workspaces()
    for i, m in ipairs(monitors_ordered()) do
        for n = 1, WS do
            hl.workspace_rule({
                workspace  = tostring((i - 1) * WS + n),
                monitor    = m.name,
                persistent = true,
                default    = (n == 1),
            })
        end
    end
end
place_workspaces()                        -- on reload (monitors known)
hl.on("hyprland.start", place_workspaces) -- at login, once monitors exist
hl.on("monitor.added", place_workspaces)

local function on_this_monitor(n, move)
    return function()
        local m = hl.get_active_monitor()
        local id = (m and ws_base(m.name) or 0) + n
        if move then
            hl.dispatch(hl.dsp.window.move({ workspace = id }))
        else
            hl.dispatch(hl.dsp.focus({ workspace = id }))
        end
    end
end

for n = 1, WS do
    bind(mainMod .. " + " .. n,         "desktop " .. n,                 on_this_monitor(n))
    bind(mainMod .. " + SHIFT + " .. n, "move window to desktop " .. n,  on_this_monitor(n, true))
end

bind(mainMod .. " + Tab",        "previous desktop",           hl.dsp.focus({ workspace = "previous" }))
bind(mainMod .. " + mouse_down", "next desktop (this monitor)", hl.dsp.focus({ workspace = "m+1" }))
bind(mainMod .. " + mouse_up",   "prev desktop (this monitor)", hl.dsp.focus({ workspace = "m-1" }))

-- Scratchpad
bind(mainMod .. " + S",         "toggle scratchpad",         hl.dsp.workspace.toggle_special("magic"))
bind(mainMod .. " + SHIFT + S", "move window to scratchpad", hl.dsp.window.move({ workspace = "special:magic" }))

-- Volume / media / brightness
bind("XF86AudioRaiseVolume",  "volume up",       hl.dsp.exec_cmd("pamixer -i 5"),                  { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  "volume down",     hl.dsp.exec_cmd("pamixer -d 5"),                  { locked = true, repeating = true })
bind("XF86AudioMute",         "mute",            hl.dsp.exec_cmd("pamixer -t"),                    { locked = true })
bind("XF86AudioMicMute",      "mute microphone", hl.dsp.exec_cmd("pamixer --default-source -t"),   { locked = true })
bind("XF86MonBrightnessUp",   "brightness up",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", "brightness down", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
bind("XF86AudioPlay",         "play / pause",    hl.dsp.exec_cmd("playerctl play-pause"),          { locked = true })
bind("XF86AudioPause",        "pause",           hl.dsp.exec_cmd("playerctl play-pause"),          { locked = true })
bind("XF86AudioNext",         "next track",      hl.dsp.exec_cmd("playerctl next"),                { locked = true })
bind("XF86AudioPrev",         "previous track",  hl.dsp.exec_cmd("playerctl previous"),            { locked = true })

-- Empty submap the settings app switches to while you press a new shortcut,
-- so Hyprland doesn't act on the keys. Escape always leaves it (and still
-- reaches the app, to cancel the dialog).
hl.define_submap("rice_capture", function()
    hl.bind("Escape", hl.dsp.submap("reset"), { non_consuming = true })
end)

-- Your app shortcuts (added in Settings -> Keybinds)
for _, app in ipairs(user_binds.apps or {}) do
    if app.keys and app.cmd then
        bind(app.keys, "app: " .. (app.name or app.cmd), hl.dsp.exec_cmd(app.cmd))
    end
end


----------------------
---- WINDOW RULES ----
----------------------

-- Ignore maximize requests from apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Float utility windows
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|nm-connection-editor|blueman-manager)$" },
    float = true,
})

-- Settings app (Super+,)
hl.window_rule({
    name  = "rice-settings",
    match = { class = "^(rice\\.settings)$" },
    float = true,
    size  = { 980, 680 },
    center = true,
})

-- Theme picker: centered floating card grid (Super+T)
hl.window_rule({
    name  = "theme-picker",
    match = { class = "^(rice\\.themepicker)$" },
    float = true,
    pin   = true,
})

-- Picture-in-Picture: float + pin
hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
})

-- Slightly translucent terminal so the blur shows through
hl.window_rule({
    name    = "terminal-opacity",
    match   = { class = "^(Alacritty|kitty)$" },
    opacity = look.terminal_opacity .. " " .. look.terminal_opacity,
})


---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "rofi" },   blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "walker" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "swaync-control-center" },      blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.3 })


-----------------------------
---- THIS MACHINE (local) ----
-----------------------------

-- Machine-specific settings -- monitor layout, extra autostarts -- go in
-- ~/.config/hypr/local.lua, which install.sh keeps across reinstalls/updates.
do
    local f = os.getenv("HOME") .. "/.config/hypr/local.lua"
    local fh = io.open(f, "r")
    if fh then
        fh:close()
        dofile(f)
    end
end
