local c = require('langmapper.config')
local h = require('langmapper.helpers')

describe('Langmapper: API', function()
  require('langmapper').setup()

  -- Mappings before `automapping()` will call
  local mappings_before = {
    ['<leader>a'] = '<leader>ф',
    ['<leader>b'] = '<leader>и',
  }

  for key, _ in pairs(mappings_before) do
    vim.keymap.set('n', key, 'l')
  end
  require('langmapper').automapping()

  local map = require('langmapper').map
  local del = require('langmapper').del
  local wrap_set = require('langmapper').wrap_nvim_set_keymap
  local wrap_del = require('langmapper').wrap_nvim_del_keymap
  local wrap_buf_set = require('langmapper').wrap_nvim_buf_set_keymap
  local wrap_buf_del = require('langmapper').wrap_nvim_buf_del_keymap

  local test_maps = {
    ['<leader>d'] = '<leader>в',
    ['<localleader>f'] = 'жа',
    ['jk'] = 'ол',
  }

  for key, val in pairs(test_maps) do
    it(('`map()`: Map "%s" and it has translated counterpart "%s"'):format(key, val), function()
      map({ 'v', 'n' }, key, 'l')
      local has_map_n = vim.fn.maparg(val, 'n') ~= ''
      local has_map_v = vim.fn.maparg(val, 'v') ~= ''
      assert.is_true(has_map_n and has_map_v)
    end)

    it(('`del()`: Delete "%s". "%s" must also be deleted'):format(key, val), function()
      del({ 'v', 'n' }, key)
      local has_map_n = vim.fn.maparg(key, 'n') ~= ''
      local has_tr_map_n = vim.fn.maparg(val, 'n') ~= ''
      local has_map_v = vim.fn.maparg(key, 'v') ~= ''
      local has_tr_map_v = vim.fn.maparg(val, 'v') ~= ''
      assert.is_false(has_map_n and has_map_v and has_tr_map_v and has_tr_map_n)
    end)

    it(('`wrap_nvim_set_keymap()`: Map "%s" and it has translated counterpart "%s"'):format(key, val), function()
      wrap_set('n', key, 'l')
      local has_map_n = vim.fn.maparg(val, 'n') ~= ''
      assert.is_true(has_map_n)
    end)

    it(('`wrap_nvim_del_keymap()`: Delete "%s". "%s" must also be deleted'):format(key, val), function()
      wrap_del('n', key)
      local has_map_n = vim.fn.maparg(key, 'n') ~= ''
      local has_tr_map_n = vim.fn.maparg(val, 'n') ~= ''
      assert.is_false(has_map_n and has_tr_map_n)
    end)

    it(('`wrap_nvim_buf_set_keymap()`: Map "%s" and it has translated counterpart "%s"'):format(key, val), function()
      local bufnr = vim.api.nvim_get_current_buf()
      wrap_buf_set(bufnr, 'n', key, 'l')

      if key:match('<leader>') then
        key = key:gsub('<leader>', vim.g.mapleader)
      elseif key:match('<localleader>') then
        key = key:gsub('<localleader>', vim.g.maplocalleader)
      end

      local buf_maps = c.original_keymaps.nvim_buf_get_keymap(bufnr, 'n')

      local has_orig = h.some(buf_maps, function(unit)
        return key:gsub('<leader>|<localleader>', ' ') == unit.lhs
      end)

      local has_tr = h.some(buf_maps, function(unit)
        return val:gsub('<leader>', ' ') == unit.lhs
      end)

      assert.is_true(has_orig and has_tr)
    end)

    it(('`wrap_nvim_buf_del_keymap()`: Delete "%s". "%s" must also be deleted'):format(key, val), function()
      local bufnr = vim.api.nvim_get_current_buf()
      wrap_buf_del(bufnr, 'n', key)

      if key:match('<leader>') then
        key = key:gsub('<leader>', vim.g.mapleader)
      elseif key:match('<localleader>') then
        key = key:gsub('<localleader>', vim.g.maplocalleader)
      end

      local buf_maps = c.original_keymaps.nvim_buf_get_keymap(bufnr, 'n')

      local has_orig = h.some(buf_maps, function(unit)
        return key:gsub('<leader>|<localleader>', ' ') == unit.lhs
      end)

      local has_tr = h.some(buf_maps, function(unit)
        return val:gsub('<leader>', ' ') == unit.lhs
      end)

      assert.is_true(not (has_orig and has_tr))
    end)
  end

  local builtins = {
    Y = 'Н',
    gx = 'пч',
    ['[%'] = 'х%',
    [']%'] = 'ъ%',
    ['g%'] = 'п%',
  }

  for key, val in pairs(builtins) do
    local rhs = vim.fn.maparg(key, 'n')
    it('`automapping()`: remaped builtins nvim "' .. key .. '" for ' .. rhs .. ' to "' .. val .. '"', function()
      local has = vim.fn.maparg(val, 'n') ~= ''
      assert.is_true(has)
    end)
  end

  for key, val in pairs(mappings_before) do
    it('`autoremap()`: remaped user mappings "' .. key .. '" to "' .. val .. '"', function()
      local has = vim.fn.maparg(val, 'n') ~= ''
      assert.is_true(has)
    end)
  end
end)
