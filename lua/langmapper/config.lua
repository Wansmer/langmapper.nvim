local M = {}

M.config = {
  ---@type boolean Add mapping for every CTRL+ binding or not. Using for remaps CTRL's neovim mappings by default.
  map_all_ctrl = true,
  ---@type boolean Remap specials keys (see layouts[youlayout].special_remap)
  remap_specials_keys = true,
  ---@type string[] If empty, will remapping for all defaults layouts
  use_layouts = {},
  ---@type boolean Execute vim.keymap.set = require('langmapper').map
  hack_keymap = false,
  ---@type string Standart English layout (only alphabetic symbols)
  default_layout = [[ABCDEFGHIJKLMNOPQRSTUVWXYZ<>:"{}~abcdefghijklmnopqrstuvwxyz,.;'[]`]],
  ---@type table Fallback layouts
  layouts = {
    ---@type table Fallback layout item
    ru = {
      ---@type string Name of your second keyboard layout in system.
      ---It should be the same as result string of `get_current_layout_id`
      id = 'com.apple.keylayout.RussianWin',
      ---@type string
      default_layout = nil, -- if you need to specify default layout specialy for this fallback layout
      ---@type string Fallback layout to remap. Should be same length as default layout
      layout = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯБЮЖЭХЪËфисвуапршолдьтщзйкыегмцчнябюжэхъё',
      --@type string Fallback extra layout to remap. Should be same length as default extra layout
      ---@type table Dictionary of pairs <leaderkeycode> and replacement
      leaders = {
        ---@type string|nil If not nil, key will be replaced in mappings
        ['<Localleader>'] = 'ж',
        ['<Leader>'] = nil,
      },
      ---@type table Using to remapping special symbols in normal mode. To use the same keys you are used to
      ---rhs: normal mode command to execute
      ---feed_mode:
      ---  n - use nvim-default behavior (like remap = false)
      ---  m - use remapping behavior if key was remmaping by user or another plugin (like remap = true)
      ---  nil - if nil, feed_mode will autodetect
      ---  (for more info see :h feedkeys(). Here use only n and m)
      ---check_layout: this causes a delay because checking the current input method is an expensive operation
      special_remap = {
        ['.'] = { rhs = '/', feed_mode = nil, check_layout = true },
        [','] = { rhs = '?', feed_mode = nil, check_layout = true },
        ['/'] = { rhs = '|', feed_mode = nil, check_layout = true },
        ['Ж'] = { rhs = ':', feed_mode = nil, check_layout = false },
        ['ж'] = { rhs = ';', feed_mode = nil, check_layout = false },
        ['ю'] = { rhs = '.', feed_mode = nil, check_layout = false },
        ['б'] = { rhs = ',', feed_mode = nil, check_layout = false },
        ['э'] = { rhs = "'", feed_mode = nil, check_layout = false },
        ['Э'] = { rhs = '"', feed_mode = nil, check_layout = false },
        ['х'] = { rhs = '[', feed_mode = nil, check_layout = false },
        ['ъ'] = { rhs = ']', feed_mode = nil, check_layout = false },
        ['Х'] = { rhs = '{', feed_mode = nil, check_layout = false },
        ['Ъ'] = { rhs = '}', feed_mode = nil, check_layout = false },
        ['ё'] = { rhs = '`', feed_mode = nil, check_layout = false },
        ['Ë'] = { rhs = '~', feed_mode = nil, check_layout = false },
      },
    },
  },
  os = {
    Darwin = {
      ---Function for getting current keyboard layout on your device
      ---Should return string with id of layouts
      ---@return string
      get_current_layout_id = function()
        local cmd =
          'defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID'
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
  M.config.use_layouts = vim.tbl_keys(M.config.layouts)
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
