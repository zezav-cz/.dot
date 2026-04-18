-- OS theme integration & notifications
-- Automatically switches Neovim's colorscheme based on the OS light/dark mode
-- and provides visually appealing, floating UI notifications.
return {
  "cormacrelf/dark-notify",
  config = function()
    require("dark_notify").run({
      schemes = {
        dark = {
          colorscheme = "gruvbox",
          background = "dark",
        },
        light = {
          colorscheme = "gruvbox",
          background = "light",
        }
      }
    })
  end,
}