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
  default_layout = [[ABCDEFGHIJKLMNOPQRSTUVWXYZ<>:"{}~abcdefghijklmnopqrstuvwxyz,.;'[]`]],
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
      layout = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯБЮЖЭХЪËфисвуапршолдьтщзйкыегмцчнябюжэхъё',
      ---@type table Dictionary of pairs: <leaderkeycode> and replacement
      leaders = {
        ---@type string|nil If not nil, key will be replaced in mappings.
        ---Useful when different characters are in place of your leader in different input methods
        ['<Localleader>'] = 'ж', -- I use local leader ';' and it 'ж' in second input method
        ['<Leader>'] = nil, -- If leader is ' ' (space), it can be nil, because space is always space
      },
      ---@type table Using to remapping special symbols in normal mode. To use the same keys you are used to
      ---rhs: normal mode command to execute
      ---feed_mode:
      ---  n - use nvim-default behavior (like remap = false)
      ---  m - use remapping behavior if key was remmaping by user or another plugin (like remap = true)
      ---  nil - if nil, feed_mode will autodetect (recomented)
      ---  (for more info see :h feedkeys(). Here use n and m only)
      special_remap = {
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
        --[[ When some When some keys conflict ]]
        -- On my second keyboard-layout, the '/' is in place of a dot ('.').
        -- I need to check current input method (check_layout) to send '/' character instead of dot.
        -- It will be work if you have `get_current_layout_id()` for your OS.
        ['.'] = { rhs = '/', feed_mode = nil, check_layout = true },
        ['/'] = { rhs = '|', feed_mode = nil, check_layout = true },
        [','] = { rhs = '?', feed_mode = nil, check_layout = true },
      },
    },
  },
  ---@type boolean Remap specials keys (see layouts[youlayout].special_remap)
  remap_specials_keys = true,
  os = {
    -- Darwin - Mac OS, the result of `vim.loop.os_uname()`
    Darwin = {
      ---Function for getting current keyboard layout on your OS
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
  M.config.use_layouts = vim.tbl_keys(M.config.layouts)
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
