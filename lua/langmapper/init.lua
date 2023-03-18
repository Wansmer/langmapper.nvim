local u = require('langmapper.utils')
local config = require('langmapper.config')

local map = vim.keymap.set
local original_set = vim.keymap.set
local del = vim.keymap.del

local M = {}

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

---Wrapper of vim.keymap.set with same contract
---@param mode string|table Same mode short names as |nvim_set_keymap()|
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param opts table|nil A table of |:map-arguments|.
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

function M.autoremap()
  u._autoremap_global()
  u._autoremap_buffer()
end

return M
