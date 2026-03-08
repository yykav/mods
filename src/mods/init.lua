local mods = {}

local module_names = {
  "fs",
  "is",
  "keyword",
  "List",
  "ntpath",
  "operator",
  "path",
  "posixpath",
  "repr",
  "runtime",
  "Set",
  "str",
  "stringcase",
  "tbl",
  "template",
  "utils",
  "validate",
}

for i = 1, #module_names do
  local name = module_names[i]
  mods[name] = "mods." .. name
end

return setmetatable({}, {
  __index = function(t, k)
    local mod = mods[k]
    if mod then
      local v = require(mod)
      rawset(t, k, v)
      return v
    end
  end,
})
