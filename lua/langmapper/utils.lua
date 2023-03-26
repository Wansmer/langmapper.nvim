local c = require('langmapper.config')
local keymap = vim.keymap.set

local M = {}

function M._bind(cb, first)
  return function(...)
    return cb(first, ...)
  end
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

---Update description of mapping
---@param old_desc string|nil
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

function M.split_multibyte(str)
  -- From: https://neovim.discourse.group/t/how-do-you-work-with-strings-with-multibyte-characters-in-lua/2437/4
  local function char_byte_count(s, i)
    local char = string.byte(s, i or 1)

    -- Get byte count of unicode character (RFC 3629)
    if char > 0 and char <= 127 then
      return 1
    elseif char >= 194 and char <= 223 then
      return 2
    elseif char >= 224 and char <= 239 then
      return 3
    elseif char >= 240 and char <= 244 then
      return 4
    end
  end

  local symbols = {}
  for i = 1, vim.fn.strlen(str), 1 do
    local len = char_byte_count(str, i)
    if len then
      table.insert(symbols, str:sub(i, i + len - 1))
    end
  end

  return symbols
end

---Translate 'lhs' to 'to_lang' layout. If in 'to_lang' layout no specified `base_layout`, uses global `base_layout`
---To translate back to English characters, set 'to_lang' to `default` and pass the name
---of the layout to translate from as the third parameter.
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param to_lang string Name of layout or 'default' if need translating back to English layout
---@param from_lang? string Name of layout.
---@return string
function M.translate_keycode(lhs, to_lang, from_lang)
  if M.lhs_forbidden(lhs) then
    return lhs
  end

  from_lang = from_lang or 'default'
  local base_layout, layout
  if to_lang == 'default' then
    layout = c.config.layouts[from_lang].default_layout or c.config.default_layout
    base_layout = c.config.layouts[from_lang].layout
  else
    base_layout = c.config.layouts[to_lang].default_layout or c.config.default_layout
    layout = c.config.layouts[to_lang].layout
  end

  local seq = M.split_multibyte(lhs)
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

---Remapping each CTRL+ sequence
function M._ctrls_remap()
  local function remap_ctrl(list, from, to)
    for _, char in ipairs(vim.fn.uniq(list)) do
      -- No use short values of modes like ' ', '!', 'l'
      local modes = c.config.ctrl_map_modes or { 'n', 'o', 'i', 'c', 't', 'v' }
      local keycode = '<C-' .. char .. '>'

      local tr_char = vim.fn.tr(char, from, to)
      local tr_keycode = '<C-' .. tr_char .. '>'
      local desc = M.update_desc(nil, 'feedkeys', keycode)
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

local function check_langmap()
  -- If `langmap` contains an escaped comma, `langmap:get()` returns not correct list.
  -- That's why split it manually.
  local rg = '[^\\\\]\\zs,\\ze'
  local lm = vim.fn.join(vim.opt.langmap:get(), ',')
  local lm_list = vim.split(vim.fn.substitute(lm, rg, '!!!', 'g'), '!!!')
  return function(char, tr_char)
    return M.some(lm_list, function(map)
      return map:find(char, 1, true) and map:find(tr_char, 1, true)
    end)
  end
end

local function feed_nmap(keys)
  keys = vim.api.nvim_replace_termcodes(keys, true, true, true)
  -- Mode always should be noremap to avoid recursion
  vim.api.nvim_feedkeys(keys, 'n', true)
end

local function collect_variant_commands(from, to)
  local res = {}
  local langmap_contains = check_langmap()

  for _, char in ipairs(vim.split(from, '')) do
    local tr_char = vim.fn.tr(char, from, to)
    if not (char == tr_char or langmap_contains(char, tr_char) or not from:find(tr_char, 1, true)) then
      res[tr_char] = { on_layout = char, on_default = tr_char }
    end
  end

  return res
end

function M._set_variant_commands()
  local os = vim.loop.os_uname().sysname
  local get_layout_id = c.config.os[os] and c.config.os[os].get_current_layout_id
  local can_check_layout = get_layout_id and type(get_layout_id) == 'function'

  if can_check_layout then
    for _, lang in ipairs(c.config.use_layouts) do
      local from = c.config.layouts[lang].default_layout or c.config.default_layout
      local to = c.config.layouts[lang].layout

      local to_check = collect_variant_commands(from, to)
      if can_check_layout then
        for key, value in pairs(to_check) do
          vim.keymap.set('n', key, function()
            if get_layout_id() == c.config.layouts[lang].id then
              feed_nmap(value.on_layout)
            else
              feed_nmap(value.on_default)
            end
          end)
        end
      end
    end
  end
end

function M._set_missing_commands()
  local langmap_contains = check_langmap()

  for _, lang in ipairs(c.config.use_layouts) do
    local from = c.config.layouts[lang].default_layout or c.config.default_layout
    local to = c.config.layouts[lang].layout
    local base_list = vim.split(from, '', { plain = true })

    for i = 1, #from do
      local char = base_list[i]
      local tr_char = vim.fn.tr(char, from, to)
      if not (char == tr_char or langmap_contains(char, tr_char) or from:find(tr_char, 1, true)) then
        vim.keymap.set('n', tr_char, function()
          feed_nmap(char)
        end)
      end
    end
  end
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
