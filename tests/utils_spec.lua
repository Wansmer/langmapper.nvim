local transcode_ru = {
  ['<leader>f'] = '<leader>а',
  ['<Leader>.'] = '<Leader>ю',
  ['<leader><Leader>'] = '<leader><Leader>',
  ['<localleader><localleader>'] = 'жж',
  ['<C-l>'] = '<C-д>',
  ['<D-l>'] = '<D-д>',
  ['<M-l>'] = '<M-д>',
  ['<A-l>'] = '<A-д>',
  ['<D-L>'] = '<D-Д>',
  ['<M-L>'] = '<M-Д>',
  ['<A-L>'] = '<A-Д>',
  ['<c-l>'] = '<c-д>',
  ['<C-Space>'] = '<C-Space>',
  ['<A-Left>'] = '<A-Left>',
  ['<C-a><C-a>'] = '<C-ф><C-ф>',
  ['<leader>>'] = '<leader>Ю',
  ['<leader>><'] = '<leader>ЮБ',
  ['<leader><>'] = '<leader>БЮ',
  ['g<C-a>'] = 'п<C-ф>',
}

describe('RussianWin input method', function()
  local utils = require('langmapper.utils')

  for from, to in pairs(transcode_ru) do
    it(('Should transcode from "%s" to "%s"'):format(from, to), function()
      assert.equals(to, utils.translate_keycode(from, 'ru'))
    end)
  end
end)
