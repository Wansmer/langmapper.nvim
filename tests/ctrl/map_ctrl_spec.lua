describe('Check if all ctrl remapped (ru)', function()
  require('langmapper').setup()

  local c = require('langmapper.config').config
  local en = c.default_layout
  local en_list = vim.split(en:lower(), '', { plain = true })
  local ru = c.layouts.ru.layout
  for _, char in ipairs(en_list) do
    local key = '<C-' .. vim.fn.tr(char, en, ru) .. '>'
    it(('Has mappings for %s'):format(key), function()
      assert.are_not.equal('', vim.fn.mapcheck(key, 'n'))
    end)
  end
end)
