local c = require('langmapper.config')
local M = {}

local function _update_flag(char, flag)
  if char:match('[<>]') then
    flag = not flag and char == '<'
    if flag and char == '>' then
      flag = not flag
    end
  end
  return flag
end

---Translate 'lhs' to another layout
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param lang table Preset for layout
---@param base_layout? string Base layout
---@return string
function M.translate_keycode(lhs, lang, base_layout)
  base_layout = base_layout or c.config.default_layout
  local seq = vim.split(lhs, '', { plain = true })
  local trans_seq = {}
  local mod_seq = ''
  local in_keycode = false
  local modificators = { ['<C-'] = true, ['<M-'] = true, ['<A-'] = true }
  local mod_len = 3

  ---Processed char:
  --- - if it inside CTRL, ALT or META - translate char, no translate special code
  --- - if it inside < .. > - no translate but do it uppercase
  --- - if it just char - translate according layout
  ---@param char string
  ---@param flag boolean Checking if char inside < .. >
  ---@param ms string Checking if char inside mod keys (CTRL, ALT, META)
  ---@return string
  local function process_char(char, flag, ms)
    local tr = vim.fn.tr
    local tr_char = tr(char, base_layout, lang.layout)
    if flag then
      return modificators[ms] and tr_char or char:upper()
    end
    return tr_char
  end

  for _, char in ipairs(seq) do
    in_keycode = _update_flag(char, in_keycode)
    mod_seq = #mod_seq < mod_len and mod_seq .. char:upper() or mod_seq

    table.insert(trans_seq, process_char(char, in_keycode, mod_seq))
  end

  local tlhs = table.concat(trans_seq, '')

  ---Force replace leaders if need
  for key, repl in pairs(lang.leaders) do
    if repl then
      tlhs = tlhs:gsub(key, repl)
    end
  end

  return tlhs
end

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

---Translate each key of table (recursive)
---@param dict table Dict-like table
---@return table
function M.trans_dict(dict)
  local trans_tbl = {}
  for key, cmd in pairs(dict) do
    for _, lang in ipairs(c.config.use_layouts) do
      trans_tbl[M.translate_keycode(key, c.config.layouts[lang])] = is_dict(cmd) and M.trans_dict(cmd) or cmd
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
      table.insert(trans_list, M.translate_keycode(str, c.config.layouts[lang]))
    end
  end
  return vim.list_extend(list, trans_list)
end

---Remapping each CTRL sequence
function M.remap_all_ctrl()
  local en_list = vim.split(c.config.default_layout:lower(), '', { plain = true })

  for _, char in ipairs(vim.fn.uniq(en_list)) do
    local modes = { '', '!', 't' }
    local keycode = '<C-' .. char .. '>'

    for _, lang in ipairs(c.config.use_layouts) do
      local tr_keycode = '<C-' .. vim.fn.tr(char, c.config.default_layout, c.config.layouts[lang].layout) .. '>'
      vim.keymap.set(modes, tr_keycode, keycode, { remap = true })
    end
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

return M
