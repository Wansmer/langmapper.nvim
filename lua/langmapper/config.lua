local M = {}

M.config = {
  ---@type boolean Add mapping for every CTRL+ binding or not.
  map_all_ctrl = true,
  ---@type boolean Wrap all keymap's functions (keymap.set, nvim_set_keymap, etc)
  hack_keymap = true,
  ---@type table Modes whose mappings will be checked during automapping.
  ---Each mode must be specified, even if some of them extend others.
  ---E.g., 'v' includes 'x' and 's', but must be listed separate.
  automapping_modes = { 'n', 'v', 'x', 's' },
  ---@type string Standart English layout (on Mac, It may be different in your case.)
  default_layout = [[~QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?`qwertyuiop[]asdfghjkl;'zxcvbnm,./]],
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
      layout = [[ËЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,ёйцукенгшщзхъфывапролджэячсмитьбю.]],
      --       [[~QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?`qwertyuiop[]asdfghjkl;'zxcvbnm,./]]
    },
  },
  os = {
    -- Darwin - Mac OS, the result of `vim.loop.os_uname()`
    Darwin = {
      ---Function for getting current input method on your OS
      ---Should return string with id of layout
      ---@return string
      get_current_layout_id = function()
        local cmd = 'im-select'
        if vim.fn.executable(cmd) then
          local output = vim.split(vim.trim(vim.fn.system(cmd)), '\n')
          return output[#output]
        end
      end,
    },
  },
}

local function check_deprecated(opts)
  if not vim.tbl_isempty(opts) then
    local msg = 'Option "%s" is deprecated. Please, check updated documentation for configure Langmapper'

    if opts.remap_specials_keys ~= nil then
      vim.notify(msg:format('remap_specials_keys'), vim.log.levels.WARN, { title = 'Langmapper:' })
    end

    for _, lang in ipairs(vim.tbl_keys(M.config.layouts)) do
      local deprecated = { 'special_remap', 'leaders' }
      for _, option in ipairs(deprecated) do
        if M.config.layouts[lang][option] then
          vim.notify(msg:format(option), vim.log.levels.WARN, { title = 'Langmapper:' })
        end
      end
    end
  end
end

local function check_layouts()
  local def_len = vim.fn.strdisplaywidth(M.config.default_layout)
  for _, lang in ipairs(vim.tbl_keys(M.config.layouts)) do
    local layout = M.config.layouts[lang]
    local len = layout.default_layout and vim.fn.strdisplaywidth(layout.default_layout) or def_len
    local l_len = vim.fn.strdisplaywidth(layout.layout)
    if len ~= l_len then
      local msg =
        'Langmapper: "default_layout" and "layout" contain different number of characters. Check your config for "%s".'
      error(msg:format(lang), 0)
    end
  end
end

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

  check_layouts()
  check_deprecated(opts)
end

return M
