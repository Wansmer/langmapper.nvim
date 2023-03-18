describe('Langmapper: API', function()
  require('langmapper').setup()

  -- Mappings before `autoremap()` will call
  local mappings_before = {
    ['<leader>a'] = '<leader>ф',
    ['<leader>b'] = '<leader>и',
  }
  for key, _ in pairs(mappings_before) do
    vim.keymap.set('n', key, 'l')
  end
  require('langmapper').autoremap()

  local utils = require('langmapper.utils')
  local map = require('langmapper').map
  local del = require('langmapper').del

  local ex1 = '<leader>d'
  local ex2 = '<localleader>f'
  local ex3 = 'jk'
  local tr_ex1 = utils.translate_keycode(ex1, 'ru')
  local tr_ex2 = utils.translate_keycode(ex2, 'ru')
  local tr_ex3 = utils.translate_keycode(ex3, 'ru')

  it('`map()`: Map ' .. ex1 .. ' and it has translated counterpart (' .. tr_ex1 .. ')', function()
    map({ 'v', 'n' }, ex1, 'l')
    local has_map_n = vim.fn.maparg(tr_ex1, 'n') ~= ''
    local has_map_v = vim.fn.maparg(tr_ex1, 'v') ~= ''
    assert.is_true(has_map_n and has_map_v)
  end)

  it('`map()`: Map ' .. ex2 .. ' and it has translated counterpart (' .. tr_ex2 .. ')', function()
    map({ 'v', 'n' }, ex2, 'l')
    local has_map_n = vim.fn.maparg(tr_ex2, 'n') ~= ''
    local has_map_v = vim.fn.maparg(tr_ex2, 'v') ~= ''
    assert.is_true(has_map_n and has_map_v)
  end)

  it('`map()`: Map ' .. ex3 .. ' and it has translated counterpart (' .. tr_ex3 .. ')', function()
    map({ 'i' }, ex3, 'l')
    local has_map_i = vim.fn.maparg(tr_ex3, 'i') ~= ''
    assert.is_true(has_map_i)
  end)

  it('`del()`: Delete ' .. ex1 .. '. "' .. tr_ex1 .. '" must also be deleted', function()
    del({ 'v', 'n' }, ex1)
    local has_map_n = vim.fn.maparg(ex1, 'n') ~= ''
    local has_tr_map_n = vim.fn.maparg(tr_ex1, 'n') ~= ''
    local has_map_v = vim.fn.maparg(tr_ex1, 'v') ~= ''
    local has_tr_map_v = vim.fn.maparg(tr_ex1, 'v') ~= ''
    assert.is_false(has_map_n and has_map_v and has_tr_map_v and has_tr_map_n)
  end)

  it('`del()`: Delete ' .. ex2 .. '. "' .. tr_ex2 .. '" must also be deleted', function()
    del({ 'v', 'n' }, ex2)
    local has_map_n = vim.fn.maparg(ex2, 'n') ~= ''
    local has_tr_map_n = vim.fn.maparg(tr_ex2, 'n') ~= ''
    local has_map_v = vim.fn.maparg(tr_ex2, 'v') ~= ''
    local has_tr_map_v = vim.fn.maparg(tr_ex2, 'v') ~= ''
    assert.is_false(has_map_n and has_map_v and has_tr_map_v and has_tr_map_n)
  end)

  it('`del()`: Delete ' .. ex3 .. '. "' .. tr_ex3 .. '" must also be deleted', function()
    del({ 'i' }, ex3)
    local has_map_i = vim.fn.maparg(ex3, 'n') ~= ''
    local has_tr_map_i = vim.fn.maparg(tr_ex3, 'n') ~= ''
    assert.is_false(has_map_i and has_tr_map_i)
  end)

  local builtins = {
    Y = 'Н',
    gx = 'пч',
    ['[%'] = 'х%',
    [']%'] = 'ъ%',
  }

  for key, val in pairs(builtins) do
    local rhs = vim.fn.maparg(key, 'n')
    it('`autoremap()`: remaped builtins nvim "' .. key .. '" for ' .. rhs .. ' to "' .. val .. '"', function()
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
