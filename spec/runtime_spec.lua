local runtime = require "mods.runtime"
local version = _VERSION

describe("mods.runtime", function()
  it("exposes version metadata", function()
    assert.are_equal(version, runtime.version)
    assert.is_number(runtime.major)
    assert.is_number(runtime.minor)
    assert.is_number(runtime.version_num)
    assert.is_boolean(runtime.is_lua51)
    assert.is_boolean(runtime.is_lua52)
    assert.is_boolean(runtime.is_lua53)
    assert.is_boolean(runtime.is_lua54)
    assert.is_boolean(runtime.is_lua55)
    assert.is_boolean(runtime.is_luajit)
    assert.is_boolean(runtime.is_windows)
  end)

  it("flags Lua versions consistently", function()
    local version_flags = {
      is_lua51 = version == "Lua 5.1",
      is_lua52 = version == "Lua 5.2",
      is_lua53 = version == "Lua 5.3",
      is_lua54 = version == "Lua 5.4",
      is_lua55 = version == "Lua 5.5",
    }

    assert.are_equal(version_flags.is_lua51, runtime.is_lua51)
    assert.are_equal(version_flags.is_lua52, runtime.is_lua52)
    assert.are_equal(version_flags.is_lua53, runtime.is_lua53)
    assert.are_equal(version_flags.is_lua54, runtime.is_lua54)
    assert.are_equal(version_flags.is_lua55, runtime.is_lua55)
  end)

  it("version_num encodes major/minor versions", function()
    local version_nums = {
      ["Lua 5.1"] = 501,
      ["Lua 5.2"] = 502,
      ["Lua 5.3"] = 503,
      ["Lua 5.4"] = 504,
      ["Lua 5.5"] = 505,
    }

    assert.are_equal(500 + runtime.minor, runtime.version_num)
    assert.are_equal(version_nums[version], runtime.version_num)
  end)

  it("detects host windows flag from package.config", function()
    assert.are_equal(package.config:sub(1, 1) == "\\", runtime.is_windows)
  end)
end)
