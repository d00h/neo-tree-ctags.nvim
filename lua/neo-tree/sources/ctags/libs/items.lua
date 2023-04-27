local renderer = require("neo-tree.ui.renderer")
local Job = require("plenary.job")

local function format_item_path(parent, name)
  if parent == nil then return name end
  parent = string.gsub(parent, "^[^:]+:", "")
  if name == nil then return parent end
  return string.format("%s.%s", parent, name)
end

local function split_by_tab(text)
  local start = 1
  local result = {}
  for pos = 1, #text do
    if text:sub(pos, pos) == "\t" and pos > 1 then
      table.insert(result, text:sub(start, pos - 1))
      start = pos + 1
    end
  end
  table.insert(result, text:sub(start))
  return result
end

local function parse_ctags_outputs(lines)
  local result = {}
  local cache = {}
  for _, line in ipairs(lines) do
    local parsed = split_by_tab(line)

    local shortname = parsed[1]
    local fullname = format_item_path(parsed[5], parsed[1])
    local filename = parsed[2]
    local pattern = parsed[3]
    local type = parsed[4]
    local parent_fullname = format_item_path(parsed[5], nil) or ""
    cache[fullname] = true
    if not cache[parent_fullname] then parent_fullname = "" end

    table.insert(result, {
      shortname = shortname,
      fullname = fullname,
      filename = filename,
      pattern = pattern,
      type = type,
      parent_fullname = parent_fullname,
    })
  end
  return result
end

local function create_result_items(ctags_items)
  local result_items = {}
  for _, ctags_item in ipairs(ctags_items) do
    local result_item = {
      id = ctags_item.fullname,
      name = ctags_item.shortname,
      type = "file",
      extra = {
        type = ctags_item.type,
        filename = ctags_item.filename,
        pattern = ctags_item.pattern,
      }
    }
    if result_items[result_item.id] == nil then -- dublicate key
      result_items[result_item.id] = result_item

      local parent_item = result_items[ctags_item.parent_fullname]
      if parent_item == nil then
        parent_item = {}
        result_items[ctags_item.parent_fullname] = parent_item
      end
      if parent_item.children == nil then parent_item.children = {} end
      table.insert(parent_item.children, result_item)
      parent_item.type = "directory"
    end
  end

  local root = result_items[""]
  if root ~= nil then
    return root.children
  end
end

local M = {}

M.get_ctags = function(filename, state)
  local on_exit = function(job, errorlevel)
    vim.schedule(function()
      local ctags_items = parse_ctags_outputs(job:result())
      local result_items = create_result_items(ctags_items)
      if result_items ~= nil then
        renderer.show_nodes(result_items, state)
      end
    end)
  end
  Job:new({
    command = "ctags",
    args = { "-o-", "--sort=no", "--output-format=u-ctags", filename },
    on_exit = on_exit,
  }):start()
end

return M
