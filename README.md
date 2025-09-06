# nvim-custom-workspace

一个自定义的 Neovim 工作区插件，通过软链接的方式将多个目录整合到一个工作区中，让 cursor agent 可以一起思考多个项目。

## 功能特性

- 🚀 **多目录工作区**: 通过软链接将多个目录整合到一个工作区
- 💬 **Cursor Agent 支持**: 让 cursor agent 可以同时访问多个项目的文件
- 🎯 **灵活管理**: 创建、删除、添加、移除目录
- 🔧 **配置持久化**: 工作区配置自动保存
- 📝 **Telescope 集成**: 通过 Telescope 选择工作区
- 🎨 **美观界面**: 现代化的 UI 设计

## 安装

在你的 LazyVim 配置中添加：

```lua
{
  "custom-workspace",
  dir = "~/prs/nvim-custom-workspace",
  event = "VeryLazy",
  config = function()
    require("custom-workspace").setup({
      -- 工作区存储目录
      workspace_dir = vim.fn.expand("~/.local/share/nvim/custom-workspaces"),
      -- 默认工作区名称
      default_name = "my-workspace",
    })
  end,
}
```

## 快捷键

| 功能 | 快捷键 | 说明 |
|------|--------|------|
| 创建工作区 | `<leader>cwn` | 创建新的工作区 |
| 打开工作区 | `<leader>cwo` | 打开工作区选择器 |
| 添加目录 | `<leader>cwa` | 添加目录到工作区 |
| 移除目录 | `<leader>cwr` | 从工作区移除目录 |
| 列出工作区 | `<leader>cwl` | 列出所有工作区 |
| 删除工作区 | `<leader>cwd` | 删除工作区 |
| 显示信息 | `<leader>cws` | 显示工作区详细信息 |

## 使用方法

### 1. 创建工作区

1. 按 `<leader>cwn` 创建工作区
2. 输入工作区名称（如 "full-stack-project"）
3. 选择是否立即添加目录

### 2. 添加目录到工作区

1. 按 `<leader>cwa` 添加目录
2. 选择目标工作区
3. 输入要添加的目录路径
4. 系统会自动创建软链接

### 3. 打开工作区

1. 按 `<leader>cwo` 打开工作区选择器
2. 选择要打开的工作区
3. 自动切换到工作区目录并打开文件树

### 4. 管理工作区

- `<leader>cwl` - 查看所有工作区列表
- `<leader>cws` - 查看工作区详细信息
- `<leader>cwr` - 从工作区移除目录
- `<leader>cwd` - 删除整个工作区

## 实际使用场景

### 场景一：全栈项目开发
```
前端项目 (/path/to/frontend)
后端项目 (/path/to/backend)
文档项目 (/path/to/docs)
```

1. 创建 "full-stack" 工作区
2. 添加前端项目目录
3. 添加后端项目目录
4. 添加文档项目目录
5. 打开工作区，cursor agent 可以同时访问所有项目

### 场景二：多项目代码审查
```
主项目 (/path/to/main-project)
依赖库 (/path/to/dependencies)
配置文件 (/path/to/configs)
```

1. 创建 "code-review" 工作区
2. 添加相关目录
3. 使用 cursor agent 进行跨项目分析

## 工作原理

1. **工作区目录**: 在 `~/.local/share/nvim/custom-workspaces/` 下创建独立目录
2. **软链接**: 将选择的目录通过软链接链接到工作区目录
3. **配置文件**: 每个工作区都有 `workspace.json` 配置文件
4. **状态管理**: 自动保存工作区的目录信息和元数据

## 配置选项

```lua
require("custom-workspace").setup({
  -- 工作区存储目录
  workspace_dir = "~/.local/share/nvim/custom-workspaces",
  -- 默认工作区名称
  default_name = "my-workspace",
})
```

## 注意事项

1. **软链接**: 需要系统支持软链接功能
2. **权限**: 确保有创建软链接的权限
3. **路径**: 使用绝对路径避免链接失效
4. **清理**: 删除工作区时会自动清理软链接

## 与 Cursor Agent 的配合

这个插件特别适合与 cursor agent 配合使用：

1. **多项目上下文**: cursor agent 可以同时访问多个项目的文件
2. **跨项目分析**: 可以进行跨项目的代码分析和重构
3. **统一工作流**: 在一个工作区中处理相关的多个项目

## 开发

这是一个本地开发项目，你可以根据需要修改和扩展功能。

## 许可证

MIT License
# nvim-custom-workspace
# nvim-custom-workspace
