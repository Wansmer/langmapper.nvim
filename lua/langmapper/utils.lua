local c = require('langmapper.config')
local M = {}

---Checking if some item of list meets the condition.
---Empty list or non-list table, returning false.
---@param tbl table List-like table
---@param cb function Callback for checking every item
---@return boolean
local function some(tbl, cb)
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

---Checking if a table is dict
---@param tbl any
---@return boolean
local function is_dict(tbl)
  if type(tbl) ~= 'table' then
    return false
  end

  local keys = vim.tbl_keys(tbl)
  return some(keys, function(a)
    return type(a) ~= 'number'
  end)
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

---Translate 'lhs' to another layout
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param lang string Name of preset for layout
---@param base_layout? string Base layout
---@return string
function M.translate_keycode(lhs, lang, base_layout)
  base_layout = base_layout or (c.config.layouts[lang].default_layout or c.config.default_layout)
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
    if flag and char:match('[-<>]') then
      return char
    end

    local tr_char = vim.fn.tr(char, base_layout, layout)

    if flag then
      if modifiers[ms] and seq[idx - 1] == '-' and seq[idx + 1] == '>' then
        return tr_char
      else
        return char
      end
    end

    return tr_char
  end

  local is_in_keycode = function(idx)
    return some(keycode_ranges, function(range)
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

  ---Force replace leaders if need
  for key, repl in pairs(c.config.layouts[lang].leaders) do
    local rg = vim.regex('\\c' .. key)
    local range = { rg:match_str(tlhs) }
    if repl and #range > 0 then
      local found = tlhs:sub(unpack(range))
      tlhs = tlhs:gsub(found, repl)
    end
  end

  return tlhs
end

---Translate each key of table (recursive)
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

---Translate each value of list
---@param list table List-like table
---@return table
function M.trans_list(list)
  local trans_list = {}
  for _, str in ipairs(list) do
    for _, lang in ipairs(c.config.use_layouts) do
      table.insert(trans_list, M.translate_keycode(str, lang))
    end
  end
  return vim.list_extend(list, trans_list)
end

---Remapping each CTRL sequence
function M.remap_all_ctrl()
  local function remap_ctrl(list, from, to)
    for _, char in ipairs(vim.fn.uniq(list)) do
      local modes = { '', '!', 't' }
      local keycode = '<C-' .. char .. '>'

      local tr_keycode = '<C-' .. vim.fn.tr(char, from, to) .. '>'
      local desc = ('Langmapper: remap %s for %s'):format(tr_keycode, keycode)
      vim.keymap.set(modes, tr_keycode, keycode, { remap = true, desc = desc })
    end
  end

  for _, lang in ipairs(c.config.use_layouts) do
    local config = c.config
    local layout = config.layouts[lang]
    local default_layout = layout.default_layout and layout.default_layout or config.default_layout

    local en_list = vim.split(default_layout:lower(), '', { plain = true })

    remap_ctrl(en_list, default_layout, config.layouts[lang].layout)
  end
end

---Checking if rhs was remapped. Return mode for feedkeys()
---If rhs was remapped by langmapper, use default nvim behavior (mode n)
---@param rhs string
---@return string
local function get_maparg(rhs)
  local arg = vim.fn.maparg(rhs, 'n')
  if arg == '' or arg:match('langmapper') then
    return 'n'
  end
  return 'm'
end

---Remapping special keys like '.', ',', ':', ';'
function M.system_remap()
  local os = vim.loop.os_uname().sysname

  local get_layout_id = c.config.os[os] and c.config.os[os].get_current_layout_id
  local can_check_layout = get_layout_id and type(get_layout_id) == 'function'

  local function feed_special(rhs_set, lhs, layout_id, feed_mode)
    return function()
      local layout = get_layout_id()
      local rhs = layout ~= layout_id and lhs or rhs_set.rhs
      vim.api.nvim_feedkeys(rhs, feed_mode, true)
    end
  end

  for _, lang in ipairs(c.config.use_layouts) do
    local special_remap = c.config.layouts[lang].special_remap
    local id = c.config.layouts[lang].id

    for lhs, rhs_set in pairs(special_remap) do
      local desc = ('Langmapper: nvim_feedkeys( %s )'):format(rhs_set.rhs)
      local feed_mode = rhs_set.feed_mode or get_maparg(rhs_set.rhs)

      if rhs_set.check_layout then
        if can_check_layout then
          local cb = feed_special(rhs_set, lhs, id, feed_mode)
          vim.keymap.set('n', lhs, cb, { desc = desc })
        end
      else
        local remap = feed_mode == 'm' and true or false
        local opts = { remap = remap, desc = desc }
        vim.keymap.set('n', lhs, rhs_set.rhs, opts)
      end
    end
  end
end

local function num_to_bool(n)
  local matches = {
    ['0'] = false,
    ['1'] = true,
  }
  return matches[tostring(n)]
end

local function collect_mapopts(maparg, opts)
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

local function to_keymap_contract(maparg)
  local booleans = { 'expr', 'noremap', 'nowait', 'script', 'silent' }
  local res = {
    lhs = '',
    rhs = '',
    desc = '',
    buffer = 0,
    mode = '',
    opts = collect_mapopts(maparg, booleans),
  }
  return collect_units(res, maparg)
end

function M.lhs_forbidden(lhs)
  local matches = { '<plug>', '<sid>', '<snr>' }
  return some(matches, function(m)
    return string.lower(lhs):match(m)
  end)
end

local function autoremap(scope)
  local modes = { 'n', 'v', 'x' }
  local mappings = {}
  local bufnr = scope == 'buffer' and vim.api.nvim_get_current_buf() or nil

  for _, mode in ipairs(modes) do
    local maps = {}
    if scope == 'buffer' then
      maps = vim.api.nvim_buf_get_keymap(bufnr, mode)
    else
      maps = vim.api.nvim_get_keymap(mode)
    end

    for _, map in ipairs(maps) do
      table.insert(mappings, map)
    end
  end

  for _, map in ipairs(mappings) do
    map = to_keymap_contract(map)
    if map.mode ~= ' ' and not M.lhs_forbidden(map.lhs) then
      local lhs = M.translate_keycode(map.lhs, 'ru'):gsub('%s', '<leader>')
      if vim.fn.maparg(lhs, map.mode) == '' then
        local rhs = function()
          local repl = vim.api.nvim_replace_termcodes(map.lhs, true, true, true)
          vim.api.nvim_feedkeys(repl, 'm', true)
        end

        local opts = vim.tbl_deep_extend('force', map.opts, { buffer = bufnr })
        local ok, info = pcall(vim.keymap.set, map.mode, lhs, rhs, opts)
        if not ok then
          vim.notify('Langmapper (autoremap_global):' .. info)
        end
      end
    end
  end
end

function M.autoremap_global()
  autoremap('global')
end

function M.autoremap_buffer()
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufRead', 'BufEnter', 'LspAttach' }, {
    callback = function(data)
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_loaded(data.buf) then
          autoremap('buffer')
        end
      end, 0)
    end,
  })
end

return M
