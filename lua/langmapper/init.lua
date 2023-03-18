local u = require('langmapper.utils')
local config = require('langmapper.config')

local map = vim.keymap.set
local del = vim.keymap.del

local M = {}

---Original function `vim.keymap.set`. Useful when `hack_keymap` is `true`
M.original_set = vim.keymap.set
---Original function `vim.keymap.del`. Useful when `hack_keymap` is `true`
M.original_del = vim.keymap.del
---Original function `nvim_set_keymap`. Useful when `hack_keymap` is `true`
M.old_set_keymap = vim.api.nvim_set_keymap
---Original function `nvim_buf_set_keymap`. Useful when `hack_keymap` is `true`
M.old_buf_set_keymap = vim.api.nvim_buf_set_keymap
---Original function `nvim_set_keymap`. Useful when `hack_keymap` is `true`
M.old_del_keymap = vim.api.nvim_del_keymap
---Original function `nvim_buf_set_keymap`. Useful when `hack_keymap` is `true`
M.old_buf_del_keymap = vim.api.nvim_buf_del_keymap

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
    M._hack_keymap()
  end
end

function M._hack_keymap()
  vim.keymap.set = M.map
  vim.keymap.del = M.del
  vim.api.nvim_set_keymap = M.wrap_nvim_set_keymap
  vim.api.nvim_buf_set_keymap = M.wrap_nvim_buf_set_keymap
  vim.api.nvim_del_keymap = M.wrap_nvim_del_keymap
  vim.api.nvim_buf_del_keymap = M.wrap_nvim_buf_del_keymap
end

---Put back all values of keymap's functions
function M.put_back_keymap()
  vim.keymap.set = M.original_set
  vim.keymap.del = M.original_del
  vim.api.nvim_set_keymap = M.old_set_keymap
  vim.api.nvim_buf_set_keymap = M.old_buf_set_keymap
  vim.api.nvim_del_keymap = M.old_del_keymap
  vim.api.nvim_buf_del_keymap = M.old_buf_del_keymap
end

---Wrapper of vim.keymap.set with same contract
---@param mode string|table Same mode short names as |nvim_set_keymap()|
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param rhs string|function Right-hand side |{rhs}| of the mapping. Can also be a Lua function.
---@param opts table|nil A table of |:map-arguments|.
function M.map(mode, lhs, rhs, opts)
  -- Default mapping
  map(mode, lhs, rhs, opts)
  -- Translated mapping
  u._map_for_layouts(mode, lhs, rhs, opts, map)
end

---Wrapper of vim.keymap.del with same contract
---@param mode string|table Same mode short names as |nvim_set_keymap()|
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param opts table|nil A table of optional arguments:
---  - buffer: (number or boolean) Remove a mapping from the given buffer.
---  When "true" or 0, use the current buffer.
function M.del(mode, lhs, opts)
  -- Default mapping
  del(mode, lhs, opts)

  mode = type(mode) == 'table' and mode or { mode }

  -- Delete translated mapping for each langs in config.use_layouts
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

---Wrapper of `nvim_set_keymap` with same contract. See `:h nvim_set_keymap()`
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
---@param rhs string  Right-hand-side |{rhs}| of the mapping.
---@param opts table Optional parameters map
function M.wrap_nvim_set_keymap(mode, lhs, rhs, opts)
  -- Default mapping
  M.old_set_keymap(mode, lhs, rhs, opts)
  -- Translated mapping
  u._map_for_layouts(mode, lhs, rhs, opts, M.old_set_keymap)
end

---Wrapper of `nvim_buf_set_keymap` with same contract. See `:h nvim_buf_set_keymap()`
---Sets a buffer-local |mapping| for the given mode.
---@param buffer integer Buffer handle, or 0 for current buffer
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
---@param rhs string  Right-hand-side |{rhs}| of the mapping.
---@param opts table Optional parameters map
function M.wrap_nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
  -- Default mapping
  M.old_buf_set_keymap(buffer, mode, lhs, rhs, opts)
  -- Translated mapping
  u._map_for_layouts(mode, lhs, rhs, opts, u._bind(M.old_buf_set_keymap, buffer))
end

---Wrapper of `nvim_del_keymap` with same contract. See `:h nvim_del_keymap()`
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
function M.wrap_nvim_del_keymap(mode, lhs)
  M.old_del_keymap(mode, lhs)
  -- Delete translated mapping for each langs in config.use_layouts
  for _, lang in ipairs(config.config.use_layouts) do
    local tr_lhs = u.translate_keycode(lhs, lang)
    local has = vim.fn.maparg(tr_lhs, mode) ~= ''

    if tr_lhs ~= lhs and has then
      M.old_del_keymap(mode, tr_lhs)
    end
  end
end

---Wrapper of `nvim_buf_del_keymap` with same contract. See `:h nvim_buf_del_keymap()`
---@param buffer integer Buffer
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
function M.wrap_nvim_buf_del_keymap(buffer, mode, lhs)
  M.old_buf_del_keymap(buffer, mode, lhs)
  -- Delete translated mapping for each langs in config.use_layouts
  for _, lang in ipairs(config.config.use_layouts) do
    local tr_lhs = u.translate_keycode(lhs, lang)
    local has = vim.fn.maparg(tr_lhs, mode) ~= ''

    if tr_lhs ~= lhs and has then
      M.old_buf_del_keymap(buffer, mode, tr_lhs)
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
