local M = {}

function M.tmpname()
  local p = os.tmpname()
  os.remove(p)
  return p
end

function M.with_env(env, fn)
  local getenv = os.getenv
  rawset(os, "getenv", function(name)
    return env[name]
  end)
  fn()
  rawset(os, "getenv", getenv)
end

return M
