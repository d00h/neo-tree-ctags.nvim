-- This file should contain all commands meant to be used by mappings.
local vim = vim
local cc = require("neo-tree.sources.common.commands")
local utils = require("neo-tree.utils")
local manager = require("neo-tree.sources.manager")

local function get_node_patterns(tree, node)
  local patterns = {}
  while node ~= nil do
    table.insert(patterns, 1, node.extra.pattern)
    local parent_id = node._parent_id
    if parent_id == nil then break end
    node = tree.nodes.by_id[parent_id]
  end
  return patterns
end

local M = {}

M.open = function(state, toggle_directory)
  local function prepare(pattern)
    pattern = string.gsub(pattern, "%[", "\\[")
    pattern = string.gsub(pattern, "%]", "\\]")
    return pattern
  end

  local tree = state.tree

  local node = tree:get_node()
  if node.type == "file" then
    local extra = node.extra or {}
    vim.cmd("e +0 " .. extra.filename)
    local patterns = get_node_patterns(tree, node)
    for _, pattern in ipairs(patterns) do
      if pattern ~= nil then vim.cmd("silent! " .. prepare(pattern)) end
    end
    vim.cmd("nohlsearch")
    return
  else
    cc.open(state, toggle_directory)
  end
end

M.refresh = function(state)
end
--
cc._add_common_commands(M)

return M
