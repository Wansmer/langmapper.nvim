local u = require('langmapper.utils')
local config = require('langmapper.config')

local map = vim.keymap.set
local del = vim.keymap.del

local M = {}

---Originals keymap's functions. Useful when `hack_keymap` is `true`
M.original_set = vim.keymap.set
M.original_del = vim.keymap.del
M.original_set_keymap = vim.api.nvim_set_keymap
M.original_buf_set_keymap = vim.api.nvim_buf_set_keymap
M.original_del_keymap = vim.api.nvim_del_keymap
M.original_buf_del_keymap = vim.api.nvim_buf_del_keymap

---Setup langmapper
---@param opts? table
function M.setup(opts)
  local ok, info = pcall(config.update_config, opts)
  if not ok then
    vim.notify(info, vim.log.error, { title = 'Langmapper:' })
    return
  end

  u._expand_langmap()

  if config.config.map_all_ctrl then
    u._ctrls_remap()
  end

  if config.config.hack_keymap then
    M._hack_keymap()
  end
end

function M._hack_keymap()
  vim.keymap.set = M._hack_keymap_set
  vim.keymap.del = M.del
  vim.api.nvim_set_keymap = M._hack_nvim_set_keymap
  vim.api.nvim_buf_set_keymap = M._hack_nvim_buf_set_keymap
  vim.api.nvim_del_keymap = M.wrap_nvim_del_keymap
  vim.api.nvim_buf_del_keymap = M.wrap_nvim_buf_del_keymap
end

---Put back all values of keymap's functions
function M.put_back_keymap()
  vim.keymap.set = M.original_set
  vim.keymap.del = M.original_del
  vim.api.nvim_set_keymap = M.original_set_keymap
  vim.api.nvim_buf_set_keymap = M.original_buf_set_keymap
  vim.api.nvim_del_keymap = M.original_del_keymap
  vim.api.nvim_buf_del_keymap = M.original_buf_del_keymap
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
---@param opts? table Optional parameters map
function M.wrap_nvim_set_keymap(mode, lhs, rhs, opts)
  opts = opts or {}
  -- Default mapping
  M.original_set_keymap(mode, lhs, rhs, opts)
  -- Translated mapping
  u._map_for_layouts(mode, lhs, rhs, opts, M.original_set_keymap)
end

---Wrapper of `nvim_buf_set_keymap` with same contract. See `:h nvim_buf_set_keymap()`
---Sets a buffer-local |mapping| for the given mode.
---@param buffer integer Buffer handle, or 0 for current buffer
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
---@param rhs string  Right-hand-side |{rhs}| of the mapping.
---@param opts? table Optional parameters map
function M.wrap_nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
  opts = opts or {}
  -- Default mapping
  M.original_buf_set_keymap(buffer, mode, lhs, rhs, opts)
  -- Translated mapping
  u._map_for_layouts(mode, lhs, rhs, opts, u._bind(M.original_buf_set_keymap, buffer))
end

---Wrapper of `nvim_del_keymap` with same contract. See `:h nvim_del_keymap()`
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
function M.wrap_nvim_del_keymap(mode, lhs)
  M.original_del_keymap(mode, lhs)
  -- Delete translated mapping for each langs in config.use_layouts
  for _, lang in ipairs(config.config.use_layouts) do
    local tr_lhs = u.translate_keycode(lhs, lang)
    local has = vim.fn.maparg(tr_lhs, mode) ~= ''

    if tr_lhs ~= lhs and has then
      M.original_del_keymap(mode, tr_lhs)
    end
  end
end

---Wrapper of `nvim_buf_del_keymap` with same contract. See `:h nvim_buf_del_keymap()`
---@param buffer integer Buffer
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
function M.wrap_nvim_buf_del_keymap(buffer, mode, lhs)
  M.original_buf_del_keymap(buffer, mode, lhs)
  -- Delete translated mapping for each langs in config.use_layouts
  for _, lang in ipairs(config.config.use_layouts) do
    local tr_lhs = u.translate_keycode(lhs, lang)
    local has = vim.fn.maparg(tr_lhs, mode) ~= ''

    if tr_lhs ~= lhs and has then
      M.original_buf_del_keymap(buffer, mode, tr_lhs)
    end
  end
end

---Gets the output of `nvim_get_keymap` for all modes listed in the `automapping_modes`,
---and sets the translated mappings using `nvim_feedkeys`.
---Then sets event handlers `{ 'BufWinEnter', 'LspAttach' }` to do the same with outputting
---`nvim_buf_get_keymap` for each open buffer.
---Must be called at the very end of `init.lua`,
---after all plugins have been loaded and all key bindings have been set.
---Does not handle mappings for lazy-loaded plugins. To avoid it, see `hack_keymap`.
---@param opts table? {global=boolean|nil, buffer=boolean|nil} Both true by default
function M.automapping(opts)
  opts = vim.tbl_extend('force', opts or {}, { buffer = true, global = true })
  if opts.global then
    u._autoremap_global()
  end
  if opts.buffer then
    u._autoremap_buffer()
  end
end

-- [[ Wrappers for `hack_keymap` ]]
-- NOTE: Must be separate functions because allowance for prohibited modes is used,
-- unlike regular wrappers (`disable_hack_modes`)

---Wrapper of vim.keymap.set with same contract (for `hack_keymap`)
---Not translated modes from `disable_hack_modes`
---@param mode string|table Same mode short names as |nvim_set_keymap()|
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param rhs string|function Right-hand side |{rhs}| of the mapping. Can also be a Lua function.
---@param opts table|nil A table of |:map-arguments|.
function M._hack_keymap_set(mode, lhs, rhs, opts)
  -- Default mapping
  map(mode, lhs, rhs, opts)

  -- Skip disabled modes
  if type(mode) == 'string' then
    mode = { mode }
  end

  mode = u._skip_disabled_modes(mode)
  -- Translated mapping
  u._map_for_layouts(mode, lhs, rhs, opts, map)
end

---Wrapper of `nvim_set_keymap` with same contract. See `:h nvim_set_keymap()`
---(for `hack_keymap`) Not translated modes from `disable_hack_modes`
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
---@param rhs string  Right-hand-side |{rhs}| of the mapping.
---@param opts? table Optional parameters map
function M._hack_nvim_set_keymap(mode, lhs, rhs, opts)
  opts = opts or {}
  -- Default mapping
  M.original_set_keymap(mode, lhs, rhs, opts)

  -- Skip disabled modes
  if not vim.tbl_contains(config.config.disable_hack_modes, mode) then
    -- Translated mapping
    u._map_for_layouts(mode, lhs, rhs, opts, M.original_set_keymap)
  end
end

---Wrapper of `nvim_buf_set_keymap` with same contract. See `:h nvim_buf_set_keymap()`
---Sets a buffer-local |mapping| for the given mode.
---(for `hack_keymap`) Not translated modes from `disable_hack_modes`
---@param buffer integer Buffer handle, or 0 for current buffer
---@param mode string Mode short-name
---@param lhs string Left-hand-side |{lhs}| of the mapping.
---@param rhs string  Right-hand-side |{rhs}| of the mapping.
---@param opts? table Optional parameters map
function M._hack_nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
  opts = opts or {}
  -- Default mapping
  M.original_buf_set_keymap(buffer, mode, lhs, rhs, opts)

  -- Skip disabled modes
  if not vim.tbl_contains(config.config.disable_hack_modes, mode) then
    -- Translated mapping
    u._map_for_layouts(mode, lhs, rhs, opts, u._bind(M.original_buf_set_keymap, buffer))
  end
end

return M
