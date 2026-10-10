-- Light/dark: follow the system preference, at startup and while running.
--
-- There is one source of truth for the whole desktop and it is gsettings'
-- `org.gnome.desktop.interface color-scheme`. The waybar applet
-- (`waybar/scripts/colorscheme.sh`) writes it; `foot-theme-watcher.sh` watches
-- it and, on every change, rewrites `~/.config/foot/theme-mode.ini` and signals
-- running foot windows to swap palettes.
--
-- Neovim hooks into the end of that chain rather than the start: it watches the
-- ini file the foot watcher already maintains. That is deliberate --
--
--   * no `gsettings` subprocess on startup, and no gsettings monitor process
--     per nvim instance;
--   * it works inside tmux, where Neovim's own OSC 11 background query does
--     not reliably reach the terminal;
--   * nvim and foot flip from the same event, so the two can't disagree. They
--     have to agree, because gruvbox runs with `transparent_mode` -- it never
--     paints `Normal`'s background, foot's shows through -- and light gruvbox
--     syntax colours on a black terminal are unreadable.
--
-- Changing `background` is all that is needed to repaint: Vim re-sources the
-- current colorscheme whenever the option changes, so gruvbox swaps palettes
-- in place with no reload and no flicker.
local M = {}

local THEME_MODE = vim.fn.expand("~/.config/foot/theme-mode.ini")

-- foot's `initial-color-theme`: 1 is its dark `[colors]` block, 2 the light
-- `[colors2]` one. Returns nil when the file is absent or unparseable, which
-- leaves `background` alone and lets Neovim's own detection decide.
local function preference()
  local f = io.open(THEME_MODE, "r")
  if not f then
    return nil
  end
  local body = f:read("*a")
  f:close()

  local theme = body:match("initial%-color%-theme%s*=%s*(%d)")
  if not theme then
    return nil
  end
  return theme == "2" and "light" or "dark"
end

-- Idempotent: re-running it when nothing changed costs one file read and does
-- not re-source the colorscheme.
function M.apply()
  local bg = preference()
  if bg and bg ~= vim.o.background then
    vim.o.background = bg
  end
end

-- Watch the *directory*, not the file. The foot watcher replaces
-- theme-mode.ini (it deletes the stow symlink and writes a real file in its
-- place), and a watch on an inode that gets unlinked stops firing after the
-- first change.
local function watch()
  local handle = vim.uv.new_fs_event()
  if not handle then
    return
  end

  local dir = vim.fn.fnamemodify(THEME_MODE, ":h")
  local name = vim.fn.fnamemodify(THEME_MODE, ":t")

  local ok = pcall(function()
    handle:start(dir, {}, function(err, changed)
      if err or changed ~= name then
        return
      end
      -- fs_event fires from the loop thread, where the Neovim API is off
      -- limits; and a single rewrite fires it more than once, which the
      -- no-op guard in apply() absorbs.
      vim.schedule(M.apply)
    end)
  end)

  if not ok then
    handle:close()
  end
end

function M.setup()
  M.apply()
  watch()
end

return M
