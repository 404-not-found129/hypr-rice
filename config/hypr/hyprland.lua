-- ─────────────────────────────────────────────────────────
--  Hyprland (Lua config) — Catppuccin Mocha
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
    hl.exec_cmd("waybar")
    hl.exec_cmd("systemctl --user reset-failed swaync xdg-desktop-portal-hyprland 2>/dev/null; systemctl --user start swaync")
    hl.exec_cmd("elephant")
    hl.exec_cmd("sleep 0.5 && walker --gapplication-service")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && wp=$(ls -t ~/.config/aether/theme/backgrounds/* 2>/dev/null | head -n1); [ -n \"$wp\" ] && ln -sf \"$wp\" ~/Pictures/wallpapers/wall.png; awww img ~/Pictures/wallpapers/wall.png --transition-type grow --transition-pos center")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
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

local accent        = aether_color("accent",   "cba6f7")
local accent2       = aether_color("cursor",   "89b4fa")
local border_muted  = aether_color("muted",    "313244")

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 12,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(" .. accent .. "ff)", "rgba(" .. accent2 .. "ff)" }, angle = 45 },
            inactive_border = "rgba(" .. border_muted .. "ff)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.95,

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = 0xcc1a1a2e,
        },

        blur = {
            enabled  = true,
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
        enabled = true,
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

        follow_mouse  = 1,
        sensitivity   = 0,
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

local mainMod = "SUPER"

-- Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(menu))

-- Window management
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))

-- Session
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("wlogout"))

-- Utilities
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("walker -m clipboard"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

-- Screenshots (saved to ~/Pictures/screenshots + clipboard)
hl.bind("Print",           hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/screenshots"))
hl.bind("SHIFT + Print",   hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures/screenshots"))
hl.bind("CTRL + Print",    hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/screenshots"))

-- Focus with mainMod + arrows
-- Theme switcher (Aether blueprints)
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.local/bin/theme-picker"))

-- Wallpaper cycling (Elden Ring collection, themed via Aether)
hl.bind(mainMod .. " + right", hl.dsp.exec_cmd("~/.local/bin/wallcycle next"))
hl.bind(mainMod .. " + left",  hl.dsp.exec_cmd("~/.local/bin/wallcycle prev"))

hl.bind(mainMod .. " + ALT + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move window with mainMod + SHIFT + arrows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))

-- Resize with mainMod + CTRL + arrows
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

-- Workspaces: mainMod + [0-9] to switch, + SHIFT to move window
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces with mainMod + wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mainMod + LMB/RMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume / media / brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("pamixer -i 5"),                  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("pamixer -d 5"),                  { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("pamixer -t"),                    { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("pamixer --default-source -t"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),          { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"),          { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),                { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),            { locked = true })


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
    opacity = "0.72 0.72",
})


---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "rofi" },   blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "walker" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "swaync-control-center" },      blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.3 })
