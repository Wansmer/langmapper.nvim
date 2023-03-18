local u = require('langmapper.utils')
local config = require('langmapper.config')

local map = vim.keymap.set
local del = vim.keymap.del

local M = {}

---Original function `vim.keymap.set`. Useful when `hack_keymap` is `true`
M.original_set = vim.keymap.set
---Original function `vim.keymap.del`. Useful when `hack_keymap` is `true`
M.original_del = vim.keymap.del

---Setup langmapper
---@param opts? table
function M.setup(opts)
  config.update_config(opts)

  if config.config.map_all_ctrl then
    u._ctrls_remap()
  end

  if config.config.remap_specials_keys then
    u._system_remap()
  end

  if config.config.hack_keymap then
    vim.keymap.set = M.map
    vim.keymap.del = M.del
  end
end

---Wrapper of vim.keymap.set with same contract
---@param mode string|table Same mode short names as |nvim_set_keymap()|
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param rhs string|function Right-hand side |{rhs}| of the mapping. Can also be a Lua function.
---@param opts table|nil A table of |:map-arguments|.
function M.map(mode, lhs, rhs, opts)
  opts = opts or nil

  -- Default mapping
  map(mode, lhs, rhs, opts)

  -- Translate mapping for each langs in config.use_layouts
  for _, lang in ipairs(config.config.use_layouts) do
    local tr_lhs = u.translate_keycode(lhs, lang)

    if not opts then
      opts = { desc = u.update_desc(nil, 'translate', lhs) }
    else
      opts.desc = u.update_desc(opts.desc, 'translate', lhs)
    end

    if tr_lhs ~= lhs then
      map(mode, tr_lhs, rhs, opts)
    end
  end
end

---Wrapper of vim.keymap.del with same contract
---@param mode string|table Same mode short names as |nvim_set_keymap()|
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param opts table|nil A table of optional arguments:
---  - buffer: (number or boolean) Remove a mapping from the given buffer.
---  When "true" or 0, use the current buffer.
function M.del(mode, lhs, opts)
  opts = opts or nil

  -- Default mapping
  del(mode, lhs, opts)

  mode = type(mode) == 'table' and mode or { mode }

  -- Translate mapping for each langs in config.use_layouts
  for _, lang in ipairs(config.config.use_layouts) do
    local tr_lhs = u.translate_keycode(lhs, lang)
    local has = u.every(mode, function(m)
      return vim.fn.maparg(tr_lhs, m) ~= ''
    end)

    if tr_lhs ~= lhs and has then
      del(mode, tr_lhs, opts)
    end
  end
end

---Gets the output of `nvim_get_keymap` for all modes listed in the `autoremap_modes`,
---and sets the translated mappings using `nvim_feedkeys`.
---Then sets event handlers `{ 'BufWinEnter', 'LspAttach' }` to do the same with outputting
---`nvim_buf_get_keymap` for each open buffer.
---Must be called at the very end of `init.lua`,
---after all plugins have been loaded and all key bindings have been set.
---Does not handle mappings for lazy-loaded plugins. To avoid it, see `hack_keymap`.
function M.autoremap()
  u._autoremap_global()
  u._autoremap_buffer()
end

return M
