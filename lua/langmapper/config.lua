local M = {}

M.config = {
  ---@type boolean Add mapping for every CTRL+ binding or not.
  map_all_ctrl = true,
  ---@type boolean Wrap all keymap's functions (keymap.set, nvim_set_keymap, etc)
  hack_keymap = false,
  ---@type table Modes whose mappings will be checked during automapping.
  ---Each mode must be specified, even if some of them extend others.
  ---E.g., 'v' includes 'x' and 's', but must be listed separate.
  automapping_modes = { 'n', 'v', 'x', 's' },
  ---@type string Standart English layout (on Mac, It may be different in your case.)
  default_layout = [[~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?`1234567890-=qwertyuiop[]\asdfghjkl;'zxcvbnm,./]],
  ---@type string[] Names of layouts. If empty, will handle all configured layouts.
  use_layouts = {},
  ---@type table Fallback layouts
  layouts = {
    ---@type table Fallback layout item. Name of key is a name of language
    ru = {
      ---@type string Name of your second keyboard layout in system.
      ---It should be the same as result string of `get_current_layout_id()`
      id = 'com.apple.keylayout.RussianWin',
      ---@type string if you need to specify default layout for this fallback layout
      default_layout = nil,
      ---@type string Fallback layout to translate. Should be same length as default layout
      layout = [[Ë!"№;%:?*()_+ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,ё1234567890-=йцукенгшщзхъ\фывапролджэячсмитьбю.]],
    },
  },
  os = {
    -- Darwin - Mac OS, the result of `vim.loop.os_uname()`
    Darwin = {
      ---Function for getting current input method on your OS
      ---Should return string with id of layout
      ---@return string
      get_current_layout_id = function()
        local cmd = '/opt/homebrew/bin/im-select'
        local output = vim.split(vim.trim(vim.fn.system(cmd)), '\n')
        return output[#output]
      end,
    },
  },
}

---Update configuration
---@param opts table|nil
function M.update_config(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)
  if opts.use_layouts and not vim.tbl_isempty(opts.use_layouts) then
    M.config.use_layouts = opts.use_layouts
  else
    M.config.use_layouts = vim.tbl_keys(M.config.layouts)
  end
end

return M
