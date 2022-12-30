local M = {}

M.config = {
  ---@type table|nil
  default_map_arguments = nil,
  ---@type string
  default_layout = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz,.',
  ---@type table
  layouts = {
    ---@type table
    ru = {
      layout = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯфисвуапршолдьтщзйкыегмцчнябю',
      id = 'RussianWin',
    },
  },
  os = {
    Darwin = {
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
  ---@type string[] If empty, will remapping for all defaults layouts
  use_layouts = {},
  ---@type boolean
  map_all_ctrl = true,
  force_replace = {
    ---@type string|boolean Every <keycode> must be in uppercase
    ['<LOCALLEADER>'] = 'б',
    ---@type string|boolean Every <keycode> must be in uppercase
    ['<LEADER>'] = false,
  },
  ---@type table
  system_remap = {
    ru = {
      [':'] = 'Ж',
      [';'] = 'ж',
      ['/'] = '.',
      ['?'] = ',',
    },
  },
}

function M.update_config(opts)
  opts = opts or {}
  M.config.use_layouts = vim.tbl_keys(M.config.layouts)
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
