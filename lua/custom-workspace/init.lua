local M = {}

-- 默认配置
local default_config = {
  workspace_dir = vim.fn.expand("~/.local/share/nvim/custom-workspaces"),
  default_name = "my-workspace",
}

-- 当前配置
local config = {}

-- 设置函数
function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})
  
  -- 确保工作区目录存在
  vim.fn.mkdir(config.workspace_dir, "p")
  
  -- 设置快捷键
  M.setup_keymaps()
end

-- 设置快捷键
function M.setup_keymaps()
  local wk = require("which-key")
  
  -- 注册 which-key group
  wk.add({
    { "<leader>cw", group = "custom workspace" },
  })
  
  -- 快捷键映射
  vim.keymap.set("n", "<leader>cwn", function() M.create_workspace() end, { desc = "Create new workspace" })
  vim.keymap.set("n", "<leader>cwo", function() M.open_workspace() end, { desc = "Open workspace" })
  vim.keymap.set("n", "<leader>cwa", function() M.add_directory() end, { desc = "Add directory to workspace" })
  vim.keymap.set("n", "<leader>cwr", function() M.remove_directory() end, { desc = "Remove directory from workspace" })
  vim.keymap.set("n", "<leader>cwl", function() M.list_workspaces() end, { desc = "List workspaces" })
  vim.keymap.set("n", "<leader>cwd", function() M.delete_workspace() end, { desc = "Delete workspace" })
  vim.keymap.set("n", "<leader>cws", function() M.show_workspace_info() end, { desc = "Show workspace info" })
end

-- 创建工作区
function M.create_workspace()
  local name = vim.fn.input("Enter workspace name: ", config.default_name)
  if name == "" then
    vim.notify("Workspace name cannot be empty", vim.log.levels.ERROR)
    return
  end
  
  local workspace_path = config.workspace_dir .. "/" .. name
  
  -- 检查工作区是否已存在
  if vim.fn.isdirectory(workspace_path) == 1 then
    vim.notify("Workspace '" .. name .. "' already exists", vim.log.levels.WARN)
    return
  end
  
  -- 创建工作区目录
  vim.fn.mkdir(workspace_path, "p")
  
  -- 创建配置文件
  local config_file = workspace_path .. "/workspace.json"
  local config_data = {
    name = name,
    created_at = os.time(),
    directories = {}
  }
  
  vim.fn.writefile({vim.json.encode(config_data)}, config_file)
  
  vim.notify("Workspace '" .. name .. "' created successfully", vim.log.levels.INFO)
  
  -- 询问是否要添加目录
  local add_dir = vim.fn.input("Add directory to workspace? (y/n): ")
  if add_dir:lower() == "y" or add_dir:lower() == "yes" then
    M.add_directory_to_workspace(name)
  end
end

-- 打开工作区
function M.open_workspace()
  local workspaces = M.get_workspace_list()
  if #workspaces == 0 then
    vim.notify("No workspaces found", vim.log.levels.WARN)
    return
  end
  
  -- 尝试使用 telescope，如果失败则使用简单选择
  local ok, telescope = pcall(require, "telescope")
  if ok then
    -- 使用 telescope 选择工作区
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    
    pickers.new({}, {
      prompt_title = "Select Workspace",
      finder = finders.new_table({
        results = workspaces,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            M.open_workspace_directory(selection.value.name)
          end
        end)
        return true
      end,
    }):find()
  else
    -- 使用简单选择
    local workspace_name = M.select_workspace(workspaces)
    if workspace_name then
      M.open_workspace_directory(workspace_name)
    end
  end
end

-- 打开工作区目录
function M.open_workspace_directory(name)
  local workspace_path = config.workspace_dir .. "/" .. name
  
  if vim.fn.isdirectory(workspace_path) ~= 1 then
    vim.notify("Workspace '" .. name .. "' not found", vim.log.levels.ERROR)
    return
  end
  
  -- 切换到工作区目录
  vim.cmd("cd " .. workspace_path)
  
  -- 刷新 Neo-tree 并打开
  vim.cmd("NvimTreeRefresh")
  vim.cmd("NvimTreeOpen")
  
  -- 确保 Neo-tree 显示新的工作区内容
  vim.defer_fn(function()
    vim.cmd("NvimTreeRefresh")
  end, 100)
  
  vim.notify("Opened workspace: " .. name, vim.log.levels.INFO)
end

-- 添加目录到工作区
function M.add_directory()
  local workspaces = M.get_workspace_list()
  if #workspaces == 0 then
    vim.notify("No workspaces found. Create one first.", vim.log.levels.WARN)
    return
  end
  
  -- 选择工作区
  local workspace_name = M.select_workspace(workspaces)
  if not workspace_name then
    return
  end
  
  M.add_directory_to_workspace(workspace_name)
end

-- 添加目录到指定工作区
function M.add_directory_to_workspace(workspace_name)
  local path = vim.fn.input("Enter directory path: ", "", "dir")
  if path == "" then
    vim.notify("Directory path cannot be empty", vim.log.levels.ERROR)
    return
  end
  
  -- 展开路径中的 ~ 和相对路径
  local expanded_path = vim.fn.expand(path)
  
  -- 检查目录是否存在
  if vim.fn.isdirectory(expanded_path) ~= 1 then
    vim.notify("Directory does not exist: " .. expanded_path, vim.log.levels.ERROR)
    return
  end
  
  local workspace_path = config.workspace_dir .. "/" .. workspace_name
  local config_file = workspace_path .. "/workspace.json"
  
  -- 读取配置文件
  local config_data = M.load_workspace_config(workspace_name)
  if not config_data then
    return
  end
  
  -- 检查目录是否已存在
  for _, dir in ipairs(config_data.directories) do
    if dir.path == expanded_path then
      vim.notify("Directory already exists in workspace", vim.log.levels.WARN)
      return
    end
  end
  
  -- 获取目录名
  local dir_name = vim.fn.fnamemodify(expanded_path, ":t")
  if dir_name == "" then
    dir_name = vim.fn.fnamemodify(expanded_path, ":h:t")
  end
  
  -- 创建软链接
  local link_path = workspace_path .. "/" .. dir_name
  if vim.fn.isdirectory(link_path) == 1 or vim.fn.filereadable(link_path) == 1 then
    vim.notify("Link name '" .. dir_name .. "' already exists", vim.log.levels.ERROR)
    return
  end
  
  -- 创建软链接
  local result = vim.fn.system("ln -s '" .. expanded_path .. "' '" .. link_path .. "'")
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to create symlink: " .. result, vim.log.levels.ERROR)
    return
  end
  
  -- 更新配置文件
  table.insert(config_data.directories, {
    name = dir_name,
    path = expanded_path,
    link_path = link_path,
    added_at = os.time()
  })
  
  -- 保存配置文件
  vim.fn.writefile({vim.json.encode(config_data)}, config_file)
  
  vim.notify("Added directory '" .. dir_name .. "' to workspace '" .. workspace_name .. "'", vim.log.levels.INFO)
end

-- 从工作区移除目录
function M.remove_directory()
  local workspaces = M.get_workspace_list()
  if #workspaces == 0 then
    vim.notify("No workspaces found", vim.log.levels.WARN)
    return
  end
  
  local workspace_name = M.select_workspace(workspaces)
  if not workspace_name then
    return
  end
  
  local config_data = M.load_workspace_config(workspace_name)
  if not config_data or #config_data.directories == 0 then
    vim.notify("No directories in workspace", vim.log.levels.WARN)
    return
  end
  
  -- 选择要移除的目录
  local dir_names = {}
  for _, dir in ipairs(config_data.directories) do
    table.insert(dir_names, dir.name)
  end
  
  local selected_dir = M.select_from_list(dir_names, "Select directory to remove")
  if not selected_dir then
    return
  end
  
  -- 找到目录信息
  local dir_info = nil
  for _, dir in ipairs(config_data.directories) do
    if dir.name == selected_dir then
      dir_info = dir
      break
    end
  end
  
  if not dir_info then
    vim.notify("Directory not found", vim.log.levels.ERROR)
    return
  end
  
  -- 删除软链接
  if vim.fn.delete(dir_info.link_path) ~= 0 then
    vim.notify("Failed to remove symlink", vim.log.levels.ERROR)
    return
  end
  
  -- 从配置中移除
  for i, dir in ipairs(config_data.directories) do
    if dir.name == selected_dir then
      table.remove(config_data.directories, i)
      break
    end
  end
  
  -- 保存配置
  local config_file = config.workspace_dir .. "/" .. workspace_name .. "/workspace.json"
  vim.fn.writefile({vim.json.encode(config_data)}, config_file)
  
  vim.notify("Removed directory '" .. selected_dir .. "' from workspace", vim.log.levels.INFO)
end

-- 列出所有工作区
function M.list_workspaces()
  local workspaces = M.get_workspace_list()
  if #workspaces == 0 then
    vim.notify("No workspaces found", vim.log.levels.INFO)
    return
  end
  
  print("Custom Workspaces:")
  print("==================")
  for _, workspace in ipairs(workspaces) do
    print("- " .. workspace.name .. " (" .. #workspace.directories .. " directories)")
  end
end

-- 删除工作区
function M.delete_workspace()
  local workspaces = M.get_workspace_list()
  if #workspaces == 0 then
    vim.notify("No workspaces found", vim.log.levels.WARN)
    return
  end
  
  local workspace_name = M.select_workspace(workspaces)
  if not workspace_name then
    return
  end
  
  local confirm = vim.fn.input("Delete workspace '" .. workspace_name .. "'? (y/n): ")
  if confirm:lower() ~= "y" and confirm:lower() ~= "yes" then
    return
  end
  
  local workspace_path = config.workspace_dir .. "/" .. workspace_name
  
  -- 删除工作区目录
  if vim.fn.delete(workspace_path, "rf") ~= 0 then
    vim.notify("Failed to delete workspace", vim.log.levels.ERROR)
    return
  end
  
  vim.notify("Deleted workspace: " .. workspace_name, vim.log.levels.INFO)
end

-- 显示工作区信息
function M.show_workspace_info()
  local workspaces = M.get_workspace_list()
  if #workspaces == 0 then
    vim.notify("No workspaces found", vim.log.levels.WARN)
    return
  end
  
  local workspace_name = M.select_workspace(workspaces)
  if not workspace_name then
    return
  end
  
  local config_data = M.load_workspace_config(workspace_name)
  if not config_data then
    return
  end
  
  print("Workspace: " .. workspace_name)
  print("Created: " .. os.date("%Y-%m-%d %H:%M:%S", config_data.created_at))
  print("Directories (" .. #config_data.directories .. "):")
  print("==================")
  
  for _, dir in ipairs(config_data.directories) do
    print("- " .. dir.name .. " -> " .. dir.path)
  end
end

-- 获取工作区列表
function M.get_workspace_list()
  local workspaces = {}
  local workspace_dirs = vim.fn.glob(config.workspace_dir .. "/*", false, true)
  
  for _, dir in ipairs(workspace_dirs) do
    local name = vim.fn.fnamemodify(dir, ":t")
    local config_file = dir .. "/workspace.json"
    
    if vim.fn.filereadable(config_file) == 1 then
      local config_data = M.load_workspace_config(name)
      if config_data then
        table.insert(workspaces, config_data)
      end
    end
  end
  
  return workspaces
end

-- 加载工作区配置
function M.load_workspace_config(name)
  local config_file = config.workspace_dir .. "/" .. name .. "/workspace.json"
  
  if vim.fn.filereadable(config_file) ~= 1 then
    return nil
  end
  
  local content = vim.fn.readfile(config_file)
  local json_str = table.concat(content, "\n")
  
  local ok, data = pcall(vim.json.decode, json_str)
  if not ok then
    vim.notify("Failed to parse workspace config: " .. name, vim.log.levels.ERROR)
    return nil
  end
  
  return data
end

-- 选择工作区
function M.select_workspace(workspaces)
  if #workspaces == 1 then
    return workspaces[1].name
  end
  
  -- 显示工作区列表
  print("Available workspaces:")
  print("====================")
  for i, workspace in ipairs(workspaces) do
    print(i .. ". " .. workspace.name .. " (" .. #workspace.directories .. " directories)")
  end
  
  -- 获取用户选择
  local choice = vim.fn.input("Enter number (1-" .. #workspaces .. "): ")
  local num = tonumber(choice)
  
  if num and num >= 1 and num <= #workspaces then
    return workspaces[num].name
  end
  
  vim.notify("Invalid selection", vim.log.levels.ERROR)
  return nil
end

-- 从列表中选择
function M.select_from_list(list, prompt)
  if #list == 0 then
    return nil
  end
  
  if #list == 1 then
    return list[1]
  end
  
  print(prompt .. ":")
  for i, item in ipairs(list) do
    print(i .. ". " .. item)
  end
  
  local choice = vim.fn.input("Enter number (1-" .. #list .. "): ")
  local num = tonumber(choice)
  
  if num and num >= 1 and num <= #list then
    return list[num]
  end
  
  return nil
end


return M