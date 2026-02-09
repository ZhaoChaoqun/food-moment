# Claude Code 配置

## GitHub 账户规则

- 本仓库的所有 Git/GitHub 操作必须使用 **ZhaoChaoqun**（个人账户）
- **禁止**使用 chaoqunzhao_microsoft（公司账户）进行任何操作
- 每次执行 GitHub 操作前，需检查当前活跃账户，若不是 ZhaoChaoqun，需先切换：
  ```bash
  gh auth switch --user ZhaoChaoqun
  ```

## Python 环境规则

- 使用 **uv** 来管理 Python 环境和依赖
- 禁止使用 pip、conda 等其他包管理工具
- 常用命令：
  - `uv init` - 初始化项目
  - `uv add <package>` - 添加依赖
  - `uv run <script>` - 运行脚本
  - `uv sync` - 同步依赖
