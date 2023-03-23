local transcode_ru = {
  ['<leader>f'] = '<leader>а',
  ['<Leader>.'] = '<Leader>ю',
  ['<leader><Leader>'] = '<leader><Leader>',
  ['<localleader><localleader>'] = 'жж',
  ['<C-l>'] = '<C-д>',
  ['<C-L>'] = '<C-д>',
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
  ['<Plug>(do_something)'] = '<Plug>(do_something)',
  ['<sid>(do_something)'] = '<sid>(do_something)',
  ['<snr>(do_something)'] = '<snr>(do_something)',
}

local transcode_en = {}

for key, val in pairs(transcode_ru) do
  -- Because not get back <localleader> and uppercase letter in CTRL
  if not key:match('<local') and not key:match('<C%-L>') then
    transcode_en[val] = key
  end
end

describe('Langmapper: utils', function()
  require('langmapper').setup()
  local utils = require('langmapper.utils')

  for from, to in pairs(transcode_ru) do
    it(('`translate_keycode()`: Should transcode from "%s" to "%s"'):format(from, to), function()
      assert.equals(to, utils.translate_keycode(from, 'ru'))
    end)
  end

  for from, to in pairs(transcode_en) do
    it(('`translate_keycode()`: Should transcode back from "%s" to "%s"'):format(from, to), function()
      assert.equals(to, utils.translate_keycode(from, 'default', 'ru'))
    end)
  end

  it('`trans_dict()`: Dicts slhould be equals', function()
    local start_dict = {
      ['s'] = false,
      ['<leader>d'] = 'copy',
      ['<leader>'] = {
        ['d'] = 'copy',
      },
      ['<localleader>'] = {
        ['a'] = 'do_something',
      },
      ['<S-TAB>'] = 'prev_source',
    }
    local expected = {
      ['s'] = false,
      ['ы'] = false,
      ['<leader>d'] = 'copy',
      ['<leader>в'] = 'copy',
      ['<leader>'] = {
        ['d'] = 'copy',
        ['в'] = 'copy',
      },
      ['<localleader>'] = {
        ['a'] = 'do_something',
      },
      ['ж'] = {
        ['a'] = 'do_something',
        ['ф'] = 'do_something',
      },
      ['<S-TAB>'] = 'prev_source',
    }
    local translated = utils.trans_dict(start_dict)

    assert:set_parameter('TableFormatLevel', -1)
    assert.are.same(expected, translated)
  end)

  it('`trans_list()`: Lists slhould be equals', function()
    local start_list = { '<leader>d', 'ab', '<S-Tab>' }
    local expected = { '<leader>d', 'ab', '<S-Tab>', '<leader>в', 'фи' }
    local translated = utils.trans_list(start_list)
    assert.are.same(expected, translated)
  end)
end)
