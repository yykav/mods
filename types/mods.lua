---@meta mods

local repr ---@module "mods.repr"
local template ---@module "mods.template"

---Entry point that exposes all modules under one table.
---@class mods
---@field is mods.is
---@field keyword mods.keyword
---@field List mods.List
---@field operator mods.operator
---@field runtime mods.runtime
---@field Set mods.Set
---@field str mods.str
---@field stringcase mods.stringcase
---@field tbl mods.tbl
---@field utils mods.utils
---@field validate mods.validate
local M = {
  repr = repr,
  template = template,
}

return M
