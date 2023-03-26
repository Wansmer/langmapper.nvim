describe('Langmapper: add missing commands', function()
  require('langmapper').setup()

  it('Has mapping for "б" => ","', function()
    local has = vim.fn.maparg('б', 'n') ~= ''
    assert.is_true(has)
  end)

  it('Has mapping for "ю" => "."', function()
    local has = vim.fn.maparg('ю', 'n') ~= ''
    assert.is_true(has)
  end)
end)
