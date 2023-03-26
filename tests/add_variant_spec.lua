describe('Langmapper: add various commands', function()
  local layout = 'ru'

  vim.loop.os_uname = function()
    return {
      sysname = 'Mock',
    }
  end

  require('langmapper').setup({
    os = {
      Mock = {
        get_current_layout_id = function()
          if layout == 'ru' then
            return 'com.apple.keylayout.RussianWin'
          else
            return 'com.apple.keylayout.ABC'
          end
        end,
      },
    },
  })

  local listener_ls = vim.api.nvim_create_namespace('LESTEN')
  local feed = ''

  local function key_listener(char)
    local key = vim.fn.keytrans(char)
    if vim.fn.char2nr(char) ~= 3 then
      feed = char
    end
  end

  vim.on_key(key_listener, listener_ls)

  after_each(function()
    feed = ''
  end)

  -- With langmap `minimal.lua` the variant commands should be
  -- {
  --   [','] = {
  --     on_default = ',',
  --     on_layout = '?',
  --   },
  --   ['.'] = {
  --     on_default = '.',
  --     on_layout = '/',
  --   },
  --   ['/'] = {
  --     on_default = '/',
  --     on_layout = '|',
  --   },
  -- }

  it('Should feed "/" on type "." with "RussianWin" layout', function()
    vim.api.nvim_feedkeys('.', 'mx', true)
    assert.are.equal('/', feed)
  end)

  it('Should feed "?" on type "," with "RussianWin" layout', function()
    vim.api.nvim_feedkeys(',', 'mx', true)
    assert.are.equal('?', feed)
  end)

  it('Should feed "|" on type "/" with "RussianWin" layout', function()
    vim.api.nvim_feedkeys('/', 'mx', true)
    assert.are.equal('|', feed)
  end)

  layout = 'en'

  it('Should feed "." on type "." with default layout', function()
    vim.api.nvim_feedkeys('.', 'mx', true)
    assert.are.equal('.', feed)
  end)

  it('Should feed "," on type "," with default layout', function()
    vim.api.nvim_feedkeys(',', 'mx', true)
    assert.are.equal(',', feed)
  end)

  it('Should feed "/" on type "/" with default layout', function()
    vim.api.nvim_feedkeys('/', 'mx', true)
    assert.are.equal('/', feed)
  end)
end)
