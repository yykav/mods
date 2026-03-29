---@class luassert.internal
local internal = {}

---Assert that a value is a `mods.List`.
function internal.list(v) end

---Assert that a value is a `mods.Set`.
function internal.set(v) end

---Assert that a value is callable.
function internal.callable(v) end

---@class luassert:luassert.internal
assert = {}

assert.is_list = internal.list
assert.is_set = internal.set
assert.is_callable = internal.callable

assert.List = internal.list
assert.Set = internal.set
assert.Callable = internal.callable
