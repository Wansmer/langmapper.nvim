describe('Langmapper: remap all ctrls', function()
  require('langmapper').setup()
  local c = require('langmapper.config').config
  local en = c.default_layout
  local en_list = vim.split(en:gsub('%u', ''), '', { plain = true })
  local ru = c.layouts.ru.layout
  for _, char in ipairs(en_list) do
    local tr_char = vim.fn.tr(char, en, ru)
    local key = '<C-' .. tr_char .. '>'
    if not en:find(tr_char, 1, true) then
      it(('Has mappings for %s'):format(key), function()
        assert.are_not.equal('', vim.fn.maparg(key, 'n'))
      end)
    end
  end
end)
