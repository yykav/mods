local mods = require "mods"

local is = mods.is
local quote = mods.utils.quote
local template = mods.template

local lower = string.lower
local tostring = tostring
local type = type

---@type mods.validate
---@diagnostic disable-next-line: missing-fields
local M = {}

local messages = {}
local validators = {}

M.messages = messages

local function render_msg(expected, got_kind, value, template_msg)
  template_msg = template_msg or messages[expected] or "expected {{expected}}, got {{got}}"
  value = type(value) == "string" and quote(value) or tostring(value)

  return template(template_msg, {
    expected = tostring(expected),
    got = got_kind == "nil" and "no value" or got_kind,
    value = value == "nil" and "no value" or value,
  })
end

function M.register(name, check, template_msg)
  local key = lower(name)

  if template_msg ~= nil then
    messages[key] = template_msg
  end

  local wrapped = function(value, override_msg)
    if check(value) then
      return true
    end
    return false, render_msg(key, type(value), value, override_msg)
  end

  validators[key] = wrapped
  M[key] = wrapped
end

for fname in ("boolean function nil number string table thread userdata"):gmatch("%S+") do
  M.register(fname, is[fname], "expected {{expected}}, got {{got}}")
end

for fname in ("false true falsy truthy integer callable"):gmatch("%S+") do
  M.register(fname, is[fname], "expected {{expected}} value, got {{value}}")
end

for _, fname in ipairs(is._path_checks) do
  M.register(fname, is[fname], "{{value}} is not a valid {{expected}} path")
end

return setmetatable(M, {
  __index = function(_, k)
    if type(k) == "string" then
      return validators[lower(k)]
    end
  end,
  __call = function(_, value, check_name, override_msg)
    check_name = check_name or "truthy"

    local validator = validators[check_name]
    if validator then
      return validator(value, override_msg)
    end

    local got_kind = type(value)
    if got_kind == check_name then
      return true
    end
    return false, render_msg(check_name, got_kind, value, override_msg)
  end,
})
