local M = {}

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

  return not vim.tbl_islist(tbl)
end

---Checks if some item of list meets the condition.
---Empty list or non-list table, returning false.
---@param tbl table List-like table
---@param cb function Callback for checking every item
---@return boolean
function M.some(tbl, cb)
  if not vim.tbl_islist(tbl) or vim.tbl_isempty(tbl) then
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
  if type(tbl) ~= 'table' or not vim.tbl_islist(tbl) or vim.tbl_isempty(tbl) then
    return false
  end

  for _, item in ipairs(tbl) do
    if not cb(item) then
      return false
    end
  end

  return true
end

return M
