local mods = require "mods"

local is = mods.is
local quote = mods.utils.quote
local template = mods.template
local validator_names = is._path_validator_names:toset()
local lower = string.lower
local fmt = string.format

---@type mods.validate
---@diagnostic disable-next-line: missing-fields
local M = {}

---@type modsValidatorMessages
local messages = {}
local validators = {}

M.messages = messages

---@param tp type
local function render_msg(expected, tp, v, tmpl)
  local vt = type(v)
  v = vt == "string" and quote(v) or tostring(v)

  if not tmpl then
    if vt ~= "string" and validator_names[expected] then
      tmpl = messages.string
      expected = "string"
    else
      expected = tostring(expected)
      tmpl = messages[expected] or "expected {{expected}}, got {{got}}"
    end
  end

  return template(tmpl, {
    expected = expected,
    got = tp == "nil" and "no value" or tp,
    value = v == "nil" and "no value" or v,
  })
end

function M.register(name, validator, tmpl)
  local key = lower(name)

  if tmpl ~= nil then
    messages[key] = tmpl
  end

  local wrapped = function(v, tmpl)
    if validator(v) then
      return true
    end
    return false, render_msg(key, type(v), v, tmpl)
  end

  validators[key] = wrapped
  M[key] = wrapped
end

for k in ("boolean function nil number string table thread userdata"):gmatch("%S+") do
  M.register(k, is[k], fmt("expected %s, got {{got}}", k))
end

for k in ("false true falsy truthy integer callable"):gmatch("%S+") do
  M.register(k, is[k], fmt("expected %s value, got {{value}}", k))
end

for k in pairs(validator_names) do
  local expected = k == "dir" and "directory" or k
  M.register(k, is[k], fmt("{{value}} is not a valid %s path", expected))
end

messages.path = "{{value}} is not a valid path"

return setmetatable(M, {
  __index = function(_, k)
    if type(k) == "string" then
      return validators[lower(k)]
    end
  end,

  ---@param validator modsValidatorName
  __call = function(_, v, validator, tmpl)
    validator = validator or "truthy"

    local validate = validators[validator]
    if validate then
      return validate(v, tmpl)
    end

    local tp = type(v)
    if tp == validator then
      return true
    end
    return false, render_msg(validator, tp, v, tmpl)
  end,
})
