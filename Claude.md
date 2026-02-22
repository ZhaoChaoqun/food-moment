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

## iOS SwiftData 规则

- 展示层数据必须使用 **`@Query`** 宏自动驱动 UI 刷新，禁止在 View/ViewModel 中手动 `modelContext.fetch()` 后赋值给状态属性
- `@Query` 声明在 View 中，ViewModel 只负责 API 调用、写入 SwiftData 等业务操作，不持有用于展示的数据数组
- 数据写入 SwiftData（insert/delete/save）后，`@Query` 会自动刷新 UI，**不需要手动通知、trigger 计数器或 NotificationCenter**
- 服务层（SyncManager、AchievementManager 等非 View 上下文）可以使用手动 `modelContext.fetch()`
- 待迁移：已完成 DiaryView、HomeView、WeightInputSheet 的 `@Query` 迁移

## 后端 Schema 规则

- 所有 Response Schema（如 `MealResponse`、`WaterLogResponse`、`WeightLogResponse`、`UserProfileResponse`）必须包含 `created_at` 和 `updated_at` 字段，保持一致性
- API 端点构造 Response 时，优先使用 `model_validate(orm_object)` 自动从 ORM 读取所有字段，避免手动构造遗漏字段导致 500 错误
- 新增数据库列后，`create_all` 不会更新已存在的表，需手动执行 `ALTER TABLE` 添加缺失列

## 后端服务规则

- 后端服务默认启动端口为 **9800**
- 启动命令：
  ```bash
  cd backend && uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 9800
  ```
- ngrok 固定域名：`sparkle-regardant-mirella.ngrok-free.dev`
- ngrok 启动命令：
  ```bash
  ngrok http 9800 --url sparkle-regardant-mirella.ngrok-free.dev
  ```
