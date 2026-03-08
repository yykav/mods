local fs = require "mods.fs"
local is = require "mods.is"
local lfs = require "lfs"
local path = require "mods.path"

local fmt = string.format

describe("mods.fs", function()
  for _, fname in ipairs(is._path_checks) do ---@diagnostic disable-line: invisible
    it(fmt("fs.%s equals is.%s", fname, fname), function()
      assert.is_function(fs["is" .. fname])
      assert.are_equal(is[fname], fs["is" .. fname])
    end)
  end

  it("aliases getcwd() to lfs.currentdir", function()
    assert.is_function(fs.getcwd)
    assert.are_equal(lfs.currentdir, fs.getcwd)
  end)
end)
