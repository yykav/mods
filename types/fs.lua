---@meta mods.fs

local lfs ---@module "lfs"
local is ---@module "mods.is"

---
---Filesystem I/O and metadata operations.
---
---## Usage
---
---```lua
---fs = require "mods.fs"
---
---fs.mkdir("tmp/cache/app", true)
---```
---
---@class mods.fs
local M = {}

---Alias of `lfs.currentdir`
M.getcwd = lfs.currentdir

---Alias of `mods.is.block`
M.isblock = is.block

---Alias of `mods.is.char`
M.ischar = is.char

---Alias of `mods.is.device`
M.isdevice = is.device

---Alias of `mods.is.dir`
M.isdir = is.dir

---Alias of `mods.is.fifo`
M.isfifo = is.fifo

---Alias of `mods.is.file`
M.isfile = is.file

---Alias of `mods.is.link`
M.islink = is.link

---Alias of `mods.is.socket`
M.issocket = is.socket

---Alias of `lfs.symlinkattributes`
M.lstat = lfs.symlinkattributes

---Alias of `lfs.rmdir`
M.rmdir = lfs.rmdir

---Alias of `lfs.attributes`
M.stat = lfs.attributes

return M
