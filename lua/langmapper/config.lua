local M = {}

M.config = {
  ---@type table|nil List of :map-arguments for using by default
  default_map_arguments = nil,
  ---@type string Standart English layout
  default_layout = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
  ---@type table
  layouts = {
    ---@type table
    ru = {
      --@type string Name of your second keyboard layout in system
      id = 'RussianWin',
      layout = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯфисвуапршолдьтщзйкыегмцчня',
      ---@type table Dictionary of pairs <leaderkeycode> and replacement
      leaders = {
        ---@type string|boolean Every <keycode> must be in uppercase
        ['<LOCALLEADER>'] = 'б',
        ['<LEADER>'] = false,
      },
      ---@type table Using to remapping special symbols in normal mode. To use the same keys you are used to
      special_remap = {
        ['Ж'] = ':',
        ['ж'] = ';',
        ['.'] = '/',
        [','] = '?',
        ['ю'] = '>',
        ['б'] = ',',
        ['э'] = "'",
        ['Э'] = '"',
      },
    },
  },
  ---@type string[] If empty, will remapping for all defaults layouts
  use_layouts = {},
  os = {
    Darwin = {
      ---Function for getting current keyboard layout on your device
      ---Should return string with id of layouts
      ---@return string
      get_current_layout_id = function()
        local keyboar_key = '"KeyboardLayout Name"'
        local cmd = 'defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | rg -w '
          .. keyboar_key
        local output = vim.fn.system(cmd)
        local cur_layout =
          vim.trim(output:match('%"KeyboardLayout Name%" = (%a+);'))
        return cur_layout
      end,
    },
  },
  ---@type boolean Add mapping for every CTRL+ binding or not. Using for remaps CTRL's neovim mappings by default.
  map_all_ctrl = true,
  -- WARNING: Very experemental. No works good yet
  try_map_specials = true,
}

---Update configuration
---@param opts table|nil
function M.update_config(opts)
  opts = opts or {}
  M.config.use_layouts = vim.tbl_keys(M.config.layouts)
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
