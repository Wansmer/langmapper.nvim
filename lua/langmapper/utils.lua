local config = require('langmapper.config').config
local M = {}

function M.translate_keycode(lhs, layout)
  local seq = vim.split(lhs, '', { plain = true })
  local trans_seq = {}
  local ctrl_seq = ''
  local flag = false

  for _, char in ipairs(seq) do
    if char:match('[<>]') then
      flag = not flag and char == '<'
      if flag and char == '>' then
        flag = not flag
      end
    end

    if #ctrl_seq < 3 then
      ctrl_seq = ctrl_seq .. char:upper()
    end

    if flag then
      local c = ctrl_seq == '<C-'
          and vim.fn.tr(char, config.default_layout, layout)
        or string.upper(char)
      table.insert(trans_seq, c)
    else
      table.insert(trans_seq, vim.fn.tr(char, config.default_layout, layout))
    end
  end

  local tlhs = table.concat(trans_seq, '')

  for key, repl in pairs(config.force_replace) do
    if repl then
      tlhs = tlhs:gsub(key, repl)
    end
  end

  return tlhs
end

function M.trans_dict(dict)
  local trans_tbl = {}
  for key, cmd in pairs(dict) do
    for _, lang in ipairs(config.use_layouts) do
      trans_tbl[M.translate_keycode(key, config.layouts[lang].layout)] = cmd
    end
  end
  return vim.tbl_deep_extend('force', dict, trans_tbl)
end

function M.set_ctrl()
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

function M.system_remap()
  local os = vim.loop.os_uname().sysname

  local get_current_layout = config.os[os]
      and config.os[os].get_current_layout_id
    or nil

  if get_current_layout then
    local function feed_system(keycode, layout_id)
      return function()
        local layout = get_current_layout()
        if layout == layout_id then
          vim.api.nvim_feedkeys(keycode, 'n', true)
        end
      end
    end

    for lang, preset in pairs(config.system_remap) do
      if vim.tbl_contains(config.use_layouts, lang) then
        for key, remap in pairs(preset) do
          vim.keymap.set('n', remap, feed_system(key, config.layouts[lang].id))
        end
      end
    end
  end
end

return M
