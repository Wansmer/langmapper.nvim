local c = require('langmapper.config')
local u = require('langmapper.utils')

-- :h map-listing
-- `v` doesn't need to expand
local short_modes = {
  [' '] = { 'n', 'v', 's', 'o' },
  ['!'] = { 'i', 'c' },
}

---Converts the mode to an array and returns an array of modes minus those not allowed
---@param mode string|string[]
---@param allowed_modes string[]
---@return string[]
local function handle_modes(mode, allowed_modes)
  if type(mode) == 'string' then
    mode = short_modes[mode] or vim.split(mode, '')
  end
  return vim.tbl_filter(function(m)
    return vim.tbl_contains(allowed_modes, m)
  end, mode)
end

---TODO: rewrite with dict for performance
local function has_map(lhs, mode, mappings)
  return u.some(mappings, function(el)
    return el.lhs == lhs and vim.tbl_contains(el.mode, mode)
  end)
end

---Collects global or local mappings, returns a filtered array without forbidden mappings
---@param fn function nvim_get_keymap|bind(nvim_buf_get_keymap, bufnr)
---@return table
local function collect_mappings(fn)
  local allowed_modes = c.config.automapping_modes or { 'n', 'v', 'x', 's' }
  local mappings = {}
  for _, mode in ipairs(allowed_modes) do
    local maps = fn(mode)
    for _, map in ipairs(maps) do
      if not u.lhs_forbidden(map.lhs) then
        local lhs, desc, modes = map.lhs, map.desc, handle_modes(map.mode, allowed_modes)
        -- map.mode = handle_modes(map.mode, allowed_modes)
        table.insert(mappings, { lhs = lhs, desc = desc, mode = modes })
      end
    end
  end
  return mappings
end

---Automapping for local/global scope
---@param scope 'local'|'global'
---@param bufnr? integer Strictly required for 'local' scope
local function automapping(scope, bufnr)
  if scope == 'local' and not bufnr then
    return
  end

  local fns = {
    ['local'] = {
      get = u._bind(vim.api.nvim_buf_get_keymap, bufnr),
      set = u._bind(vim.api.nvim_buf_set_keymap, bufnr),
    },
    ['global'] = {
      get = vim.api.nvim_get_keymap,
      set = vim.api.nvim_set_keymap,
    },
  }

  local mappings = collect_mappings(fns[scope].get)

  for _, lang in ipairs(c.config.use_layouts) do
    for _, map in ipairs(mappings) do
      local lhs = u.translate_keycode(map.lhs, lang)
      for _, mode in ipairs(map.mode) do
        if not (map.lhs == lhs or has_map(lhs, mode, mappings)) then
          local rhs = function()
            local repl = vim.api.nvim_replace_termcodes(map.lhs, true, true, true)
            vim.api.nvim_feedkeys(repl, 'm', true)
          end

          -- No need original opts because uses `nvim_feedkeys()`
          local opts = {
            callback = rhs,
            desc = u.update_desc(map.desc, 'feedkeys', map.lhs),
          }

          fns[scope].set(mode, lhs, '', opts)
        end
      end
    end
  end
end

local M = {}

---Registering translated mappings for global scope
function M.global_automapping()
  automapping('global')
end

---Registering translated mappings for buffer-local scope
function M.local_automapping()
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'LspAttach' }, {
    callback = function(data)
      vim.schedule(function()
        if vim.api.nvim_buf_is_loaded(data.buf) then
          automapping('local', data.buf)
        end
      end)
    end,
  })
end

return M
