local config = require('langmapper.config').config
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
  base_layout = base_layout or config.default_layout
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
    for _, lang in ipairs(config.use_layouts) do
      trans_tbl[M.translate_keycode(key, config.layouts[lang])] = is_dict(cmd)
          and M.trans_dict(cmd)
        or cmd
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
    for _, lang in ipairs(config.use_layouts) do
      table.insert(trans_list, M.translate_keycode(str, config.layouts[lang]))
    end
  end
  return vim.list_extend(list, trans_list)
end

---Remapping each CTRL sequence
function M.remap_all_ctrl()
  local en_list = vim.split(config.default_layout, '', { plain = true })
  for _, char in ipairs(en_list) do
    local modes = { '', '!', 't' }
    local keycode = '<C-' .. char .. '>'

    for _, lang in ipairs(config.use_layouts) do
      local tr_keycode = '<C-'
        .. vim.fn.tr(char, config.default_layout, config.layouts[lang].layout)
        .. '>'
      vim.keymap.set(modes, tr_keycode, keycode)
    end
  end
end

---Collect all special keys
---@return table
local function collect_all_specials()
  local spec = {}
  for _, lang in ipairs(config.use_layouts) do
    spec = vim.tbl_flatten({
      spec,
      vim.tbl_keys(config.layouts[lang].special_remap),
    })
  end
  return spec
end

---Get lang object by keyboard layout id
---@param id string
---@return table|nil
local function get_lang_by_id(id)
  for _, lang in ipairs(config.use_layouts) do
    if config.layouts[lang].id == id then
      return config.layouts[lang]
    end
  end
  return nil
end

---Remapping special keys like '.', ',', ':', ';'
function M.system_remap()
  local os = vim.loop.os_uname().sysname

  if not config.os[os] then
    return
  end

  local ns = vim.api.nvim_create_namespace('langmapper')
  local spec_list = collect_all_specials()

  local get_layout_id = config.os[os].get_current_layout_id

  if get_layout_id and type(get_layout_id) == 'function' then
    local function feed_special(realpress, keycode, layout_id)
      return function()
        local layout = get_layout_id()
        if layout == layout_id then
          vim.api.nvim_feedkeys(realpress, 'n', true)
        else
          vim.api.nvim_feedkeys(keycode, 'n', true)
        end
      end
    end

    for _, lang in ipairs(config.use_layouts) do
      local special_remap = config.layouts[lang].special_remap
      local id = config.layouts[lang].id
      for key, remap in pairs(special_remap) do
        vim.keymap.set('n', key, feed_special(remap, key, id))
      end
    end
  end
end

return M
