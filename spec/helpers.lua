local M = {}

function M.tmpname()
  local p = os.tmpname()
  os.remove(p)
  return p
end

return M
