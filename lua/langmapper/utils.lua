local c = require('langmapper.config')
local keymap = vim.keymap.set

local M = {}

---Convert 0/1 to false/true
---@param n integer
---@return boolean
local function num_to_bool(n)
  local matches = {
    ['0'] = false,
    ['1'] = true,
  }
  return matches[tostring(n)]
end

---Checks if some item of list meets the condition.
---Empty list or non-list table, returning false.
---@param tbl table List-like table
---@param cb function Callback for checking every item
---@return boolean
function M.some(tbl, cb)
  if not vim.tbl_islist(tbl) or vim.tbl_isempty(tbl) then
    return false
  end

  for _, item in ipairs(tbl) do
    if cb(item) then
      return true
    end
  end

  return false
end

---Checking if every item of list meets the condition.
---Empty list or non-list table, returning false.
---@param tbl table List-like table
---@param cb function Callback for checking every item
---@return boolean
function M.every(tbl, cb)
  if type(tbl) ~= 'table' or not vim.tbl_islist(tbl) or vim.tbl_isempty(tbl) then
    return false
  end

  for _, item in ipairs(tbl) do
    if not cb(item) then
      return false
    end
  end

  return true
end

---Checks if a table is dict
---@param tbl any
---@return boolean
local function is_dict(tbl)
  if type(tbl) ~= 'table' then
    return false
  end

  local keys = vim.tbl_keys(tbl)
  return M.some(keys, function(a)
    return type(a) ~= 'number'
  end)
end

---Update description of mapping
---@param old_desc|nil string
---@param method string
---@param lhs string
---@return string
function M.update_desc(old_desc, method, lhs)
  old_desc = old_desc and old_desc or ''
  local pack = old_desc ~= '' and old_desc .. ' ' or ''
  local new_desc = pack .. 'LM (' .. method .. ' ' .. '"' .. lhs .. '")'
  return new_desc
end

---Return list of tuples where first elem - start index of keycode, last - end index of keycode
---@param key_seq string[] Lhs like list of chars
---@return table
local function get_keycode_ranges(key_seq)
  local ranges = {}

  for i, char in ipairs(key_seq) do
    if char == '<' then
      table.insert(ranges, { i })
    end

    if char == '>' then
      local last = ranges[#ranges]
      if last and #last < 2 then
        table.insert(last, i)
      end
    end
  end

  ranges = vim.tbl_filter(function(item)
    return #item == 2 and (item[2] - item[1]) > 2
  end, ranges)

  return ranges
end

---Translate 'lhs' to 'lang' layout. If in 'lang' layout no specified `base_layout`, uses global `base_layout`
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param lang string Name of preset for layout
---@return string
function M.translate_keycode(lhs, lang)
  if M.lhs_forbidden(lhs) then
    return lhs
  end

  local base_layout = c.config.layouts[lang].default_layout or c.config.default_layout
  local layout = c.config.layouts[lang].layout
  local seq = vim.split(lhs, '', { plain = true })
  local keycode_ranges = get_keycode_ranges(seq)
  local trans_seq = {}
  local in_keycode = false
  local modifiers = { ['<C-'] = true, ['<M-'] = true, ['<A-'] = true, ['<D-'] = true }

  local modifiers_seq = ''
  local modifiers_len = 3

  ---Processed char:
  --- - if it inside CTRL, ALT or META - translate char, no translate special code
  --- - if it inside < .. > - no translate but do it uppercase
  --- - if it just char - translate according layout
  ---@param char string
  ---@param flag boolean Checking if char inside < .. >
  ---@param ms string Checking if char inside mod keys (CTRL, ALT, META)
  ---@param idx integer Index of current char in sequence
  ---@return string
  local function process_char(char, flag, ms, idx)
    local in_modifier = modifiers[ms] and seq[idx - 1] == '-' and seq[idx + 1] == '>'

    if flag and (char:match('[-<>]') or not in_modifier) then
      return char
    end

    local tr_char = vim.fn.tr(char, base_layout, layout)

    -- Ctrl shouldn't be mapped with uppercase letter
    if ms == '<C-' then
      tr_char = vim.fn.tr(char:lower(), base_layout, layout)
    end

    return tr_char
  end

  local is_in_keycode = function(idx)
    return M.some(keycode_ranges, function(range)
      return idx >= range[1] and idx <= range[2]
    end)
  end

  for i, char in ipairs(seq) do
    in_keycode = is_in_keycode(i)
    -- Reset value of `modifiers_seq` on end `keycode`
    if not in_keycode then
      modifiers_seq = ''
    else
      modifiers_seq = #modifiers_seq < modifiers_len and modifiers_seq .. char:upper() or modifiers_seq
    end

    table.insert(trans_seq, process_char(char, in_keycode, modifiers_seq, i))
  end

  local tlhs = table.concat(trans_seq, '')

  local leaders = {
    ['<LEADER>'] = vim.g.mapleader,
    ['<LOCALLEADER>'] = vim.g.maplocalleader,
  }

  for leader, val in pairs(leaders) do
    if base_layout:find(val, 1, true) then
      local repl = vim.fn.tr(val, base_layout, layout)
      local rg = vim.regex('\\c' .. leader)
      local range = { rg:match_str(tlhs) }
      if repl and #range > 0 then
        local found = tlhs:sub(unpack(range))
        tlhs = tlhs:gsub(found, repl)
      end
    end
  end

  return tlhs
end

---Translates each key of table for all layouts in `use_layouts` option (recursive)
---@param dict table Dict-like table
---@return table
function M.trans_dict(dict)
  local trans_tbl = {}
  for key, cmd in pairs(dict) do
    for _, lang in ipairs(c.config.use_layouts) do
      trans_tbl[M.translate_keycode(key, lang)] = is_dict(cmd) and M.trans_dict(cmd) or cmd
    end
  end
  return vim.tbl_deep_extend('force', dict, trans_tbl)
end

---Translates each value of the list for all layouts in `use_layouts` option. Non-string value is ignored.
---Translated value will be added to the end.
---@param list table List-like table
---@return table Copy of passed list with new translated values
function M.trans_list(list)
  local trans_list = vim.list_extend({}, list)
  for _, str in ipairs(list) do
    if type(str) == 'string' then
      for _, lang in ipairs(c.config.use_layouts) do
        local tr_val = M.translate_keycode(str, lang)
        if tr_val ~= str then
          table.insert(trans_list, M.translate_keycode(str, lang))
        end
      end
    end
  end
  return trans_list
end

---Remapping each CTRL sequence
function M._ctrls_remap()
  local function remap_ctrl(list, from, to)
    for _, char in ipairs(vim.fn.uniq(list)) do
      -- No use short values of modes like ' ', '!', 'l'
      local modes = { 'n', 'x', 's', 'o', 'i', 'c', 't', 'v' }
      local keycode = '<C-' .. char .. '>'

      local tr_char = vim.fn.tr(char, from, to)
      local tr_keycode = '<C-' .. tr_char .. '>'
      local desc = M.update_desc(keycode, 'feedkeys', tr_keycode)
      -- Prevent recursion
      if not from:find(tr_char, 1, true) then
        local term_keycodes = vim.api.nvim_replace_termcodes(keycode, true, true, true)
        keymap(modes, tr_keycode, function()
          vim.api.nvim_feedkeys(term_keycodes, 'm', true)
        end, { desc = desc })
      end
    end
  end

  for _, lang in ipairs(c.config.use_layouts) do
    local config = c.config
    local layout = config.layouts[lang]
    local default_layout = layout.default_layout and layout.default_layout or config.default_layout
    -- Mapping with ctrl is case-insensitive, but will work only with lower-case remap. Prevents double mappings.
    local lowers_and_special = default_layout:gsub('%u', '')
    local en_list = vim.split(lowers_and_special, '', { plain = true })

    remap_ctrl(en_list, default_layout, config.layouts[lang].layout)
  end
end

---Checking if rhs was remapped. Return mode for feedkeys()
---If rhs was remapped by langmapper, use default nvim behavior (mode n)
---@param rhs string
---@return string
local function get_feedkeys_mode(rhs)
  local arg = vim.fn.maparg(rhs, 'n')
  if arg == '' or arg:match('langmapper') then
    return 'n'
  end
  return 'm'
end

function M._expand_langmap()
  local os = vim.loop.os_uname().sysname
  local get_layout_id = c.config.os[os] and c.config.os[os].get_current_layout_id
  local can_check_layout = get_layout_id and type(get_layout_id) == 'function'
  local lm = vim.opt.langmap:get()

  local function in_langmap(char, tr_char)
    return M.some(lm, function(map)
      return map:find(char, 1, true) and map:find(tr_char, 1, true)
    end)
  end

  for _, lang in ipairs(c.config.use_layouts) do
    local base = c.config.layouts[lang].default_layout or c.config.default_layout
    local map = c.config.layouts[lang].layout
    local base_list = vim.split(base, '', { plain = true })
    local feed = function(keys)
      local mode = get_feedkeys_mode(keys)
      keys = vim.api.nvim_replace_termcodes(keys, true, true, true)
      vim.api.nvim_feedkeys(keys, mode, true)
    end

    for i = 1, #base do
      local char = base_list[i]
      local tr_char = vim.fn.tr(char, base, map)
      if char ~= tr_char and not in_langmap(char, tr_char) then
        if not base:find(tr_char, 1, true) then
          vim.keymap.set('n', tr_char, function()
            feed(char)
          end)
        elseif can_check_layout then
          vim.keymap.set('n', tr_char, function()
            if get_layout_id() == c.config.layouts[lang].id then
              feed(char)
            else
              feed(tr_char)
            end
          end, { desc = 'Langmapper: (feedkeys)' })
        end
      end
    end
  end
end

---Collects keys/values for opts in `vim.keymap.set` with boolean values
---@param maparg table unit of result of vim.api.nvim_get_keymap()
---@param opts string[] List of target opts
---@return table<string, boolean>
local function collect_bool_opts(maparg, opts)
  local res = {}
  for _, opt in ipairs(opts) do
    if maparg[opt] then
      res[opt] = num_to_bool(maparg[opt])
    end
  end

  return res
end

local function collect_units(units, maparg)
  for unit, _ in pairs(units) do
    if unit == 'rhs' then
      units[unit] = maparg[unit] and maparg[unit] or maparg.callback
    elseif maparg[unit] then
      units[unit] = maparg[unit]
    end
  end
  return units
end

---Convert `nvim_get_keymap()` unit to `vim.keymap.set` args and opts
---@param maparg table
---@return table
local function to_keymap_contract(maparg)
  local booleans = { 'expr', 'noremap', 'nowait', 'script', 'silent' }
  local opts = vim.tbl_extend('force', {
    buffer = maparg.buffer,
    desc = maparg.desc,
  }, collect_bool_opts(maparg, booleans))

  if opts.noremap then
    opts.remap = not opts.noremap
    opts.noremap = nil
  end

  local res = { lhs = '', rhs = '', mode = '', opts = opts }
  return collect_units(res, maparg)
end

---Checks if lhs if forbidden
---@param lhs string
---@return boolean
function M.lhs_forbidden(lhs)
  local matches = { '<plug>', '<sid>', '<snr>' }
  return M.some(matches, function(m)
    return string.lower(lhs):match(m)
  end)
end

---TODO: rewrite with dict for performance
---@param lhs string Translated lhs
---@param map table map-data
---@param mappings table List of mapping
---@return boolean
local function has_map(lhs, map, mappings)
  return M.some(mappings, function(el)
    return el.lhs == lhs and el.mode == map.mode and el.buffer == map.opts.buffer
  end)
end

local function autoremap(scope)
  local modes = c.config.automapping_modes or { 'n', 'v', 'x', 's' }
  local bufnr = scope == 'buffer' and vim.api.nvim_get_current_buf() or nil
  local mappings = {}

  for _, mode in ipairs(modes) do
    local maps = {}
    if scope == 'buffer' then
      maps = vim.api.nvim_buf_get_keymap(bufnr, mode)
    else
      maps = vim.api.nvim_get_keymap(mode)
    end

    for _, map in ipairs(maps) do
      if vim.trim(map.mode) ~= '' and not M.lhs_forbidden(map.lhs) then
        table.insert(mappings, map)
      end
    end
  end

  for _, map in ipairs(mappings) do
    map = to_keymap_contract(map)
    for _, lang in ipairs(c.config.use_layouts) do
      local lhs = M.translate_keycode(map.lhs, lang)

      if not has_map(lhs, map, mappings) then
        local rhs = function()
          local repl = vim.api.nvim_replace_termcodes(map.lhs, true, true, true)
          vim.api.nvim_feedkeys(repl, 'm', true)
        end

        -- No need original opts because uses `nvim feedkeys()`
        local opts = {
          -- `bufnr` must be nill for `global` scope, otherwise the keymap will not be global
          buffer = bufnr,
          desc = M.update_desc(map.opts.desc, 'feedkeys', map.lhs),
        }

        local mode = map.mode
        if #mode > 1 then
          mode = vim.split(mode, '')
        end

        local ok, info = pcall(keymap, mode, lhs, rhs, opts)
        if not ok then
          vim.notify('Langmapper (autoremap):' .. info)
        end
      end
    end
  end
end

---Adds translated mappings for global
function M._autoremap_global()
  autoremap('global')
end

---Adds translated mappings for buffer
function M._autoremap_buffer()
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'LspAttach' }, {
    callback = function(data)
      vim.schedule(function()
        if vim.api.nvim_buf_is_loaded(data.buf) then
          autoremap('buffer')
        end
      end)
    end,
  })
end

function M._bind(cb, first)
  return function(...)
    return cb(first, ...)
  end
end

function M._skip_disabled_modes(modes)
  local allowed_modes = {}
  for _, mode in ipairs(modes) do
    if not vim.tbl_contains(c.config.disable_hack_modes, mode) then
      table.insert(allowed_modes, mode)
    end
  end
  return allowed_modes
end

-- Translate mapping for each langs in config.use_layouts
function M._map_for_layouts(mode, lhs, rhs, opts, map_cb)
  if type(mode) == 'table' and vim.tbl_isempty(mode) then
    return
  end

  for _, lang in ipairs(c.config.use_layouts) do
    local tr_lhs = M.translate_keycode(lhs, lang)

    if not opts then
      opts = { desc = M.update_desc(nil, 'translate', lhs) }
    else
      opts.desc = M.update_desc(opts.desc, 'translate', lhs)
    end

    if tr_lhs ~= lhs then
      map_cb(mode, tr_lhs, rhs, opts)
    end
  end
end

return M
