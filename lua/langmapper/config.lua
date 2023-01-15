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
      id = 'com.apple.keylayout.RussianWin',
      layout = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯфисвуапршолдьтщзйкыегмцчня',
      ---@type table Dictionary of pairs <leaderkeycode> and replacement
      leaders = {
        ---@type string|boolean Every <keycode> must be in uppercase
        ['<LOCALLEADER>'] = 'б',
        ['<LEADER>'] = false,
      },
      ---@type table Using to remapping special symbols in normal mode. To use the same keys you are used to
      ---WARNING: it will no work if you have not a function for get current layout on your system
      ---DOUBLE WARNING: it is works not enough good
      ---rhs: normal mode command to execute
      ---feed_mode:
      ---  n - use nvim-default behavior,
      ---  m - use remapping behavior if key was remmaping by user or another plugin
      ---  (for more info and variants see :h feedkeys())
      ---check_layout: this causes a delay because checking the current input method is an expensive operation
      special_remap = {
        ['.'] = { rhs = '/', feed_mode = nil, check_layout = true },
        [','] = { rhs = '?', feed_mode = nil, check_layout = true },
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
        local cmd =
          'defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID'
        local output = vim.split(vim.trim(vim.fn.system(cmd)), '\n')
        return output[#output]
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
