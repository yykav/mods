---@meta mods.posixpath

---
---Lexical path operations for POSIX-style paths.
---
---> [!NOTE]
--->
---> Python `posixpath`-style behavior, ported to Lua.
---
---## Usage
---
---```lua
---posixpath = require "mods.posixpath"
---
---print(posixpath.join("/usr", "bin")) --> "/usr/bin"
---```
---
---@class mods.posixpath
local M = {}

--------------------------------------------------------------------------------
------------------------- Normalization & Predicates ---------------------------
--------------------------------------------------------------------------------

---
---Normalize case for POSIX paths.
---
---> [!NOTE]
--->
---> This is a no-op for POSIX semantics.
---
---```lua
---posixpath.normcase("/A/B") --> "/A/B"
---```
---
---@param s string Input path value.
---@return string value Path after POSIX case normalization.
---@nodiscard
function M.normcase(s) end

---
---Join path components.
---
---> [!NOTE]
--->
---> Single input is returned as-is.
---
---```lua
---posixpath.join("/usr", "bin") --> "/usr/bin"
---```
---
---@param a string First path component.
---@param ... string Additional path components.
---@return string value Joined POSIX path.
---@nodiscard
function M.join(a, ...) end

---
---Normalize separators and dot segments.
---
---```lua
---posixpath.normpath("/a//./b/..") --> "/a"
---```
---
---@param path string Input path.
---@return string value Normalized path.
---@nodiscard
function M.normpath(path) end

---
---Return `true` when `path` is absolute.
---
---```lua
---posixpath.isabs("/a/b") --> true
---```
---
---@param path string Input path.
---@return boolean value True when `path` is absolute.
---@nodiscard
function M.isabs(path) end

--------------------------------------------------------------------------------
------------------------------ Path Decomposition ------------------------------
--------------------------------------------------------------------------------

---
---Split path into directory head and tail component.
---
---```lua
---posixpath.split("/a/b.txt") --> "/a", "b.txt"
---```
---
---@param path string Input path.
---@return string head Directory portion.
---@return string tail Final path component.
---@nodiscard
function M.split(path) end

---
---Split path into a root and extension.
---
---```lua
---posixpath.splitext("archive.tar.gz") --> "archive.tar", ".gz"
---```
---
---@param path string Input path.
---@return string root Path without the final extension.
---@return string ext Final extension including leading dot.
---@nodiscard
function M.splitext(path) end

---
---Split drive prefix from remainder.
---
---```lua
---posixpath.splitdrive("/a/b") --> "", "/a/b"
---```
---
---> [!NOTE]
--->
---> Split drive prefix (always empty on POSIX) from remainder.
---
---@param path string Input path.
---@return string drive Drive prefix (always empty on POSIX).
---@return string rest Path remainder.
---@nodiscard
function M.splitdrive(path) end

---
---Split path into drive, root, and tail components.
---
---```lua
---posixpath.splitroot("/a/b") --> "", "/", "a/b"
---```
---
---@param path string Input path.
---@return string drive Drive prefix (always empty on POSIX).
---@return string root Root separator segment.
---@return string tail Remaining path without leading root separator.
---@nodiscard
function M.splitroot(path) end

---
---Return final path component.
---
---```lua
---posixpath.basename("/a/b.txt") --> "b.txt"
---```
---
---@param path string Input path.
---@return string value Final path component.
---@nodiscard
function M.basename(path) end

---
---Return directory portion of a path.
---
---```lua
---posixpath.dirname("/a/b.txt") --> "/a"
---```
---
---@param path string Input path.
---@return string value Parent directory path.
---@nodiscard
function M.dirname(path) end

--------------------------------------------------------------------------------
------------------------------ Environment Expand ------------------------------
--------------------------------------------------------------------------------

---
---Expand `~` home segment when available.
---
---```lua
---posixpath.expanduser("~/tmp") --> "<HOME>/tmp" (when HOME is set)
---```
---
---@param path string Input path.
---@return string value Path with `~` expanded when possible.
---@nodiscard
function M.expanduser(path) end

--------------------------------------------------------------------------------
------------------------------- Derived Paths ----------------------------------
--------------------------------------------------------------------------------

---
---Return normalized absolute path.
---
---```lua
---posixpath.abspath("/a/./b") --> "/a/b"
---```
---
---@param path string Input path.
---@return string value Absolute normalized path.
---@nodiscard
function M.abspath(path) end

---
---Return `path` relative to optional `start` path.
---
---```lua
---posixpath.relpath("/a/b/c", "/a") --> "b/c"
---```
---
---@param path string Input path.
---@param start? string Optional base path.
---@return string value Path relative to `start` (or current directory when omitted).
---@nodiscard
function M.relpath(path, start) end

---
---Return longest common sub-path from a path list.
---
---```lua
---posixpath.commonpath({ "/a/b/c", "/a/b/d" }) --> "/a/b"
---```
---
---@param paths string[] List of POSIX paths.
---@return string value Longest common sub-path, or empty string when `paths` is empty.
---@nodiscard
function M.commonpath(paths) end

return M
