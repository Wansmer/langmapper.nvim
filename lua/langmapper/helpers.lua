local M = {}

M.is_list = vim.fn.has('nvim-0.10') == 1 and vim.islist or vim.tbl_islist

---Bind first param to function
---@param cb function
---@param first any First param
---@return function
function M.bind(cb, first)
  return function(...)
    return cb(first, ...)
  end
end

---Checks if a table is dict
---@param tbl any
---@return boolean
function M.is_dict(tbl)
  if type(tbl) ~= 'table' then
    return false
  end

  return not M.is_list(tbl)
end

---Checks if some item of list meets the condition.
---Empty list or non-list table, returning false.
---@param tbl table List-like table
---@param cb function Callback for checking every item
---@return boolean
function M.some(tbl, cb)
  if not M.is_list(tbl) or vim.tbl_isempty(tbl) then
    return false
  end

  for _, item in ipairs(tbl) do
    if cb(item) then
      return true
    end
  end

  return false
end

---Checking if every item of list meets the condition.
---Empty list or non-list table, returning false.
---@param tbl table List-like table
---@param cb function Callback for checking every item
---@return boolean
function M.every(tbl, cb)
  if type(tbl) ~= 'table' or not M.is_list(tbl) or vim.tbl_isempty(tbl) then
    return false
  end

  for _, item in ipairs(tbl) do
    if not cb(item) then
      return false
    end
  end

  return true
end

function M.split_multibyte(str)
  -- From: https://neovim.discourse.group/t/how-do-you-work-with-strings-with-multibyte-characters-in-lua/2437/4
  local function char_byte_count(s, i)
    local char = string.byte(s, i or 1)

    -- Get byte count of unicode character (RFC 3629)
    if char > 0 and char <= 127 then
      return 1
    elseif char >= 194 and char <= 223 then
      return 2
    elseif char >= 224 and char <= 239 then
      return 3
    elseif char >= 240 and char <= 244 then
      return 4
    end
  end

  local symbols = {}
  for i = 1, vim.fn.strlen(str), 1 do
    local len = char_byte_count(str, i)
    if len then
      table.insert(symbols, str:sub(i, i + len - 1))
    end
  end

  return symbols
end

return M
