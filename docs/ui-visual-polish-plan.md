# FoodMoment iOS 视觉深度打磨计划

> **文档版本**: v1.0
> **创建日期**: 2026-02-23
> **目标**: 从纯视觉美学 (Visual Aesthetics) 角度，对 FoodMoment 进行一次系统级的视觉升级
> **原则**: 遵循 Apple Human Interface Guidelines，追求"原生高级感"而非花哨堆砌

---

## 一、整体视觉基调定义 (The iOS Vibe of FoodMoment)

### 当前状态评估

FoodMoment 目前已具备一套较完整的设计系统 (`AppTheme`)，使用了 SF Pro Rounded + 狮尾圆体的字体组合、毛玻璃卡片 (Glass Morphism) 风格和统一的绿色主色调。整体视觉已具雏形，但存在以下核心问题：

1. **色彩体系缺少暗黑模式适配**: 几乎所有自定义颜色都是硬编码的固定 hex 值（如 `#F8F9FA`, `#0F172A`），在 Dark Mode 下无法自动反转，会出现"白底白字"或"黑色块在暗色背景上隐形"的严重问题。
2. **主色调 `#13EC5B` 饱和度过高**: 这个活力绿在大面积使用时过于刺眼，缺少美食类 App 应有的温暖感和高级感，更像健身/运动 App 的色调。
3. **排版缺少系统化节奏**: 字号和字重大量通过 `.Jakarta.bold(28)` 等硬编码方式使用，缺少真正的语义化 Type Scale，字号阶梯不规律（11, 12, 13, 14, 15, 16, 17, 18, 20, 24, 28, 32, 36, 44, 48），过于细碎。
4. **圆角过大且不分层级**: `CornerRadius.small = 16` 已经偏大，`medium = 24`, `large = 32`, `extraLarge = 40` 在小组件上会显得极度膨胀且不符合 HIG 的比例感。
5. **阴影生硬缺少层次**: 现有阴影虽然方向正确 (.black.opacity)，但缺少色彩倾向性的柔和效果。
6. **`.glassCard()` 中 `RoundedRectangle` 未使用 `.continuous` 圆角**: 缺失苹果标志性的超椭圆平滑圆角。
7. **AnalysisView 内容区背景硬编码 `Color.white`**: Dark Mode 下会变成刺眼的白色块。

### 目标视觉基调

**"温暖自然、通透轻盈、精致克制"**

- **温暖自然**: 主色从高饱和荧光绿微调为更温润的翡翠绿/薄荷绿，传递健康且有食欲的情绪
- **通透轻盈**: 保留毛玻璃效果但控制用量，核心卡片使用半透明背景 + 极柔和阴影
- **精致克制**: 字号收拢为 5-6 个标准阶梯，间距统一为 8pt 网格，细节处见功力

---

## 二、全局视觉常量与扩展优化计划 (Design Tokens)

### 2.1 色彩系统重构

#### 问题清单

| 问题 | 当前状态 | 严重程度 |
|------|---------|---------|
| 所有自定义颜色无 Dark Mode 适配 | `Color(hex: "#...")` 固定值 | **P0 严重** |
| 主色 `#13EC5B` 荧光感过强 | 对比度在浅色背景上不足，且缺少温度 | P1 |
| 文本色 `textPrimary` / `textSecondary` / `textTertiary` 是固定 hex | Dark Mode 下不可读 | **P0 严重** |
| `premiumBackground()` 渐变仅有 Light Mode 方案 | Dark Mode 下显示为刺眼的浅色背景 | **P0 严重** |
| `background = #F8F9FA` 未使用系统语义色 | 与系统 grouped background 不协调 | P1 |
| AnalysisView 内容区硬编码 `Color.white` | Dark Mode 下为白色块 | **P0 严重** |

#### 修改方案

- [ ] **[P0] 引入 Asset Catalog Color Sets**: 在 `Assets.xcassets` 中为以下颜色创建 Color Set（支持 Any/Dark 两套变体），替换 `Color(hex:)`:
  - `AppBackground` (Light: `#F8F9FA` → Dark: `#000000` 纯黑或 `#1C1C1E`)
  - `CardBackground` (Light: systemBackground → Dark: secondarySystemBackground)
  - `TextPrimary` (Light: `#1A1A2E` → Dark: `#F5F5F7`)
  - `TextSecondary` (Light: `#6B7280` → Dark: `#A1A1AA`)
  - `TextTertiary` (Light: `#9CA3AF` → Dark: `#71717A`)
  - `TrackGray` (Light: `#E2E8F0` → Dark: `#2C2C2E`)
  - `Divider` (Light: `#F1F5F9` → Dark: `#2C2C2E`)
  - `DragIndicator` (Light: `#CBD5E1` → Dark: `#48484A`)

- [ ] **[P0] `premiumBackground()` 增加 Dark Mode 分支**: 检测 `colorScheme`，Dark Mode 下使用更深沉的深绿/深蓝渐变（如 `#0A0F1A` → `#0F1A12`），而非硬编码的浅色渐变

- [ ] **[P0] `AnalysisView.nutritionContentSection` 替换 `Color.white`**: 改用 `Color(.systemBackground)` 或新的 `AppBackground` 语义色

- [ ] **[P1] 主色优化**: 将 `#13EC5B` 调整为更温润的翡翠绿调，建议 `#34C759`（Apple 系统绿）或 `#2DD4BF`（薄荷绿），保留品牌辨识度的同时降低荧光感。同步更新所有衍生色（`calorieRingProgress`, `accent` 等）

- [ ] **[P1] 文本色改用系统语义色或 Asset Catalog 适配色**: 将 `AppTheme.Colors.textPrimary/Secondary/Tertiary` 的实现改为从 Asset Catalog 读取，或直接使用 `.primary`, `.secondary`

- [ ] **[P2] 餐食类型颜色 Dark Mode 微调**: `breakfast #FACC15`（黄色）、`dinner #F87171`（红色）在 Dark Mode 下可能过于刺眼，需降低亮度 10-15%

- [ ] **[P2] 渐变和 RadialGradient 中的硬编码颜色统一审查**: 如 `DiarySummaryBar` 中的进度条使用了 `Color(hex: "#34C759")` 而非 `AppTheme.Colors.primary`，需统一

### 2.2 排版系统收拢 (Typography Scale)

#### 问题清单

| 问题 | 当前状态 | 严重程度 |
|------|---------|---------|
| 字号阶梯过于细碎 | 10/11/12/13/14/15/16/17/18/20/24/28/32/36/44/48 共 16 档 | P1 |
| 语义化 Text Style Modifier 使用率低 | `titleStyle()`, `headlineStyle()` 等仅在 Font+Custom.swift 声明，实际代码几乎全部手动写 `.Jakarta.bold(28)` | P1 |
| `numberStyle()` 固定 48pt | 不同场景数字大小需求不同，缺少阶梯 | P2 |
| 部分字号不符合 HIG 基准 | HIG 推荐 largeTitle=34, title=28, title2=22, title3=20, headline=17, body=17, callout=16, subheadline=15, footnote=13, caption=12, caption2=11 | P1 |

#### 修改方案

- [ ] **[P1] 收拢字号到 7 档标准阶梯** (对齐 HIG Dynamic Type Scale):

  | Token 名 | 字号 | 字重 | 用途 |
  |----------|------|------|------|
  | `displayLarge` | 44pt | .bold | 核心数字（卡路里百分比等） |
  | `displaySmall` | 28pt | .bold | 页面主标题、用户名 |
  | `headline` | 20pt | .semibold | Section 标题（成就、今日食刻等） |
  | `titleSmall` | 17pt | .semibold | 卡片标题（体重、日记月标题） |
  | `body` | 15pt | .regular | 正文、描述性文字 |
  | `caption` | 13pt | .medium | 辅助信息（日期、单位、副标题） |
  | `micro` | 11pt | .semibold | 徽章、标签、极小文字 |

- [ ] **[P1] 将 Font+Custom.swift 中的 View Extension 更新为新阶梯**: 重命名并简化 `titleStyle()`, `headlineStyle()` 等，使实际语义与 HIG 对齐

- [ ] **[P1] 全局搜索替换散落的硬编码字号**: 将 `.Jakarta.bold(28)` 统一替换为语义化调用如 `.font(.appFont(.bold, size: AppTheme.Typography.displaySmall))`，或更简洁的 `.font(.appDisplaySmall)`

- [ ] **[P2] 数字专用字号阶梯**: 增加 `numberLarge = 44pt`, `numberMedium = 28pt`, `numberSmall = 20pt` 三档，用于统计数字、卡路里数值、体重等

- [ ] **[P2] 核心大数字增加 tracking 微调**: 对 `displayLarge`（44pt）的数字设置 `tracking: -0.5` 增强紧凑感，对 `micro`（11pt）的全大写文字设置 `tracking: 1.5` 提升可读性

### 2.3 间距与布局网格修正 (Spacing Grid)

#### 问题清单

| 问题 | 当前状态 | 严重程度 |
|------|---------|---------|
| 水平 padding 不统一 | HomeView 用 `20`，ProfileView 用 `16`，DiaryView header 用 `20` 但搜索栏用 `16` | P1 |
| VStack spacing 不一致 | HomeView `20`，ProfileView `24`，StatisticsView `20` | P1 |
| 卡片内部 padding 不统一 | CalorieRingCard `24`, WeightCard/StreakCard `16`, WaterCard/StepsCard `20`, AIInsight `20` | P1 |
| `AppTheme.Spacing` 定义了 xs(4)/small(8)/medium(12)/large(16)/xl(20)/xxl(24) 但使用率极低 | 大部分地方直接写数字 | P1 |

#### 修改方案

- [ ] **[P1] 统一全局水平 padding 为 `20pt`**: 所有页面级 ScrollView 内容的水平间距统一为 20pt（即 `AppTheme.Spacing.xl`），ProfileView 从 16 改为 20

- [ ] **[P1] 统一 Section 间的垂直间距为 `24pt`**: 所有页面内的 section 之间使用 `AppTheme.Spacing.xxl`（24pt）

- [ ] **[P1] 统一卡片内 padding 为 `20pt`**: 将 WeightCard/StreakCard 的内部 padding 从 16 改为 20，与 WaterCard/StepsCard/CalorieRingCard 一致

- [ ] **[P2] 将散落的魔法数字替换为 `AppTheme.Spacing` 常量**: 全局搜索 `.padding(12)`, `.padding(16)`, `.padding(20)`, `.padding(24)` 等，按就近原则映射到 `Spacing.medium`, `Spacing.large`, `Spacing.xl`, `Spacing.xxl`

- [ ] **[P2] LazyVGrid 的 spacing 统一**: Health Metrics Grid 中 `spacing: 12` 与其他区域不协调，建议统一为 `Spacing.large (16)`

### 2.4 圆角系统重新校准

#### 问题清单

| 问题 | 当前状态 | 严重程度 |
|------|---------|---------|
| `CornerRadius.small = 16` 偏大 | 搜索框、MacroIndicator 等小元素也用 16pt 圆角，比例失调 | P1 |
| 未使用 `.continuous` 圆角风格 | `glassCard()`, `WaterCard`, `StepsCard` 等的 `RoundedRectangle` 都是默认圆角 | **P0** |
| 圆角档位过少且起步过高 | 缺少 8pt, 12pt 档位给小型元素用 | P1 |

#### 修改方案

- [ ] **[P0] 全局 `RoundedRectangle` 添加 `style: .continuous`**: 这是苹果标志性的"超椭圆"平滑圆角，需修改以下位置:
  - `glassCard()`, `glassSection()` 中的所有 `RoundedRectangle`
  - `WaterCard`, `StepsCard` 的 cardBackground 和 cardBorder
  - `MacroIndicatorItem` 的 itemBackground
  - `FoodMomentCard` 的 `.clipShape(RoundedRectangle(cornerRadius: 32))`
  - `FoodPhotoCard` 的图片 clipShape
  - `AIInsightDarkCard` 的 background `.clipShape(RoundedRectangle(cornerRadius: 20))`
  - `ActivityCalendar` 的 `.glassCard(cornerRadius: 32)`
  - `SearchBarSection` 的搜索框背景 `RoundedRectangle(cornerRadius: 10)`
  - `GradientButton` 的 Capsule（Capsule 天然是 continuous，无需修改）
  - 搜索结果缩略图 `RoundedRectangle(cornerRadius: 8)`

- [ ] **[P1] 重新校准圆角阶梯**:

  | Token | 当前值 | 建议值 | 使用场景 |
  |-------|-------|--------|---------|
  | `xs` (新增) | — | 8pt | 缩略图、小标签、进度条 |
  | `small` | 16pt | 12pt | 输入框、搜索框、小卡片 |
  | `medium` | 24pt | 20pt | 标准卡片、Sheet |
  | `large` | 32pt | 28pt | 大卡片（CalorieRing Card、FoodMoment Card） |
  | `extraLarge` | 40pt | 36pt | TabBar、特殊全宽容器 |

### 2.5 阴影系统重建

#### 问题清单

| 问题 | 当前状态 | 严重程度 |
|------|---------|---------|
| 阴影颜色全部基于纯黑 | `.black.opacity(0.05~0.08)` 显得生硬 | P1 |
| `GlowShadow` 使用 `primary.opacity(0.4)` 过于浓烈 | 绿色发光不够精致 | P1 |
| 卡片之间阴影层级无区分 | Glass/Glow/Card 三种但使用场景模糊 | P2 |

#### 修改方案

- [ ] **[P1] 阴影颜色添加色彩倾向**: 将 `GlassShadow` 改为 `Color(hex: "#0F172A").opacity(0.06)` (深蓝灰)，`CardShadow` 改为 `Color(hex: "#0F172A").opacity(0.08)`，避免纯黑

- [ ] **[P1] `GlowShadow` 降低外溢**: 将 `.opacity(0.4)` 降为 `.opacity(0.25)`，将 `radius: 15` 降为 `radius: 10`，使发光更内敛

- [ ] **[P1] 增加阴影的 Y 轴偏移**: `GlassShadow` 目前 `y: 8`，略大；建议 `radius: 10, y: 4`。`CardShadow` 的 `radius: 20, y: 10` 偏强，建议 `radius: 16, y: 6`

- [ ] **[P2] Dark Mode 下阴影策略**: Dark Mode 阴影几乎不可见，改用 1px 的微弱亮边 (`.overlay(RoundedRectangle(...).stroke(.white.opacity(0.06), lineWidth: 1))`) 来区分层级

---

## 三、核心页面/组件具体视觉修改清单

### 3.1 全局共享组件

#### `View+Glass.swift` — 毛玻璃卡片
- [ ] **[P0]** 所有 `RoundedRectangle` 添加 `style: .continuous`
- [ ] **[P1]** `.glassCard()` 的白底 opacity 从 `0.6` 降为 `0.5` 增加通透度
- [ ] **[P1]** Dark Mode 分支: 白色背景改为 `.white.opacity(0.05)`, 边框改为 `.white.opacity(0.08)`
- [ ] **[P1]** `premiumBackground()` 增加 `@Environment(\.colorScheme)` 检测，Dark Mode 使用深色渐变

#### `CustomTabBar.swift`
- [ ] **[P1]** TabBar 背景圆角添加 `.continuous` 风格
- [ ] **[P1]** 未选中 Tab 文字色 `.gray.opacity(0.7)` 改用 `.secondary` 以自适应暗色模式
- [ ] **[P2]** 中央 Scan 按钮的阴影色跟随主色调优化后同步更新
- [ ] **[P2]** Tab 标签字号从 10pt 提升至 11pt（`micro` 阶梯），增强可读性

#### `GradientButton.swift`
- [ ] **[P1]** `GlowShadow` 效果跟随全局阴影优化同步更新
- [ ] **[P2]** 按压态缩放从 `0.95` 微调为 `0.97`，更符合 iOS 原生的含蓄触感

#### `EmptyStateView.swift`
- [ ] **[P2]** 图标容器从 100pt 缩至 88pt，避免空状态过于占位
- [ ] **[P2]** 标题和副标题间距从 16pt 收为 12pt，整体更紧凑

### 3.2 Home 页

#### `HomeView.swift` — 头部区域
- [ ] **[P1]** 日期标签 `tracking: 1.2` 偏大，建议 `tracking: 0.8`
- [ ] **[P1]** 问候语渐变 `.primary.opacity(0.7)` 末端颜色过于浅淡，建议 `.primary.opacity(0.85)`
- [ ] **[P2]** PRO 徽章偏移 `offset(x:2, y:2)` 可能被圆形头像裁切区域遮挡，调整为 `offset(x: 4, y: 4)` 并确保 zIndex 正确

#### `CalorieRingChart.swift`
- [ ] **[P2]** Ring lineWidth 24pt 在 220pt 画布中占比偏高（11%），建议降为 20pt 使环心数字有更多呼吸空间
- [ ] **[P2]** 超标发光 `shadow radius: 12` 过于夺目，建议 `radius: 8`

#### `WaterCard.swift` / `StepsCard.swift`
- [ ] **[P0]** `RoundedRectangle(cornerRadius: cardCornerRadius)` 添加 `style: .continuous`
- [ ] **[P1]** 卡片圆角当前 32pt 对半屏宽卡片偏大，跟随全局圆角调整至 28pt
- [ ] **[P1]** 内部 padding 保持 20pt（已一致）
- [ ] **[P1]** 加号按钮阴影 `.black.opacity(0.06)` 改为带色彩倾向的柔和阴影
- [ ] **[P2]** 进度条 track 色 `Color.gray.opacity(0.15)` 改用 `AppTheme.Colors.trackGray` 语义色
- [ ] **[P2]** 进度条高度 6pt 可微增至 7pt，主视觉占位更充分

#### `FoodMomentCarousel.swift` / `FoodMomentCard`
- [ ] **[P0]** FoodMomentCard `.clipShape(RoundedRectangle(cornerRadius: 32))` 添加 `.continuous`
- [ ] **[P1]** 卡片尺寸 220x280 在 Pro Max 设备上偏小，建议改为比例计算: width = screenWidth * 0.55, height = width * 1.27
- [ ] **[P2]** 底部渐变 `.black.opacity(0.6)` 偏重，建议 `0.5` 让图片更通透
- [ ] **[P2]** 餐食类型 Badge 的 `.opacity(0.85)` 背景可改为毛玻璃效果增加高级感

#### `MacroIndicatorRow.swift`
- [ ] **[P0]** `MacroIndicatorItem` 的背景 `RoundedRectangle(cornerRadius: 16)` 添加 `.continuous`
- [ ] **[P1]** 圆角从 16pt 调整为 `CornerRadius.small`（新值 12pt），与小组件比例匹配

### 3.3 Diary 页

#### `DiaryView.swift` — Header
- [ ] **[P1]** 搜索按钮圆形背景的 `.fill(.white.opacity(0.7))` 在 Dark Mode 需适配
- [ ] **[P1]** 搜索栏的 `Color(.systemGray6)` 背景：Dark Mode 下已自适应，无需修改 [已符合]
- [ ] **[P2]** Header 底部渐变分隔线 `primary.opacity(0.2)` 可微调为 `0.15`，更含蓄

#### `DiarySummaryBar`
- [ ] **[P1]** 进度条颜色使用了 `Color(hex: "#34C759")` 而非 `AppTheme.Colors.primary`，需统一
- [ ] **[P2]** 进度条 track 色 `Color.gray.opacity(0.12)` 改用 `AppTheme.Colors.trackGray`

#### `TimelineEntry.swift`
- [ ] **[P2]** Timeline 线条色 `AppTheme.Colors.trackGray` 跟随 Dark Mode 适配即可
- [ ] **[P2]** 节点 dot 外层光环 `mealColor.opacity(0.2)` 在 Dark Mode 下可能过暗，需确认

#### `FoodPhotoCard.swift`
- [ ] **[P0]** 图片 clipShape `RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)` 添加 `.continuous`
- [ ] **[P1]** Tag 标签背景 `primary.opacity(0.06)` 在 Dark Mode 下几乎不可见，需要提高 opacity 到 0.12 并增加边框亮度

### 3.4 Statistics 页

#### `StatisticsView.swift`
- [ ] **[P1]** "统计" 标题 `.Jakarta.extraBold(32)` 字号偏大于 HIG 系统 (largeTitle=34)，建议统一为 `displaySmall` 28pt
- [ ] **[P1]** 日历按钮样式与 DiaryView 搜索按钮相同，已保持一致 [已符合]
- [ ] **[P2]** weeklyAverageCard 的 `.glassCard()` 内部文字间距可以更精致

#### `AIInsightDarkCard.swift`
- [ ] **[P0]** 背景 clipShape `RoundedRectangle(cornerRadius: 20)` 添加 `.continuous`
- [ ] **[P1]** 内容文本行距 `lineSpacing: 4` 略大，建议 `lineSpacing: 3`
- [ ] **[P2]** 右上角发光效果 `blur(radius: 40)` 可微增至 `blur(radius: 50)` 使光晕更柔和

### 3.5 Profile 页

#### `ProfileView.swift`
- [ ] **[P1]** 水平 padding 从 `16` 统一为 `20`，与其他页面一致
- [ ] **[P1]** 头像编辑指示器的白色圆形 `.fill(.white)` Dark Mode 下需改为 `Color(.systemBackground)`
- [ ] **[P2]** "编辑资料" 按钮的 Capsule 边框 `primary.opacity(0.3)` 偏淡，建议 `0.4`
- [ ] **[P2]** 顶部 "我的" 标题栏 `.background(.clear)` 在快速滚动时缺少背景模糊，建议添加 `.background(.ultraThinMaterial)` + 条件触发

#### `WeightCard.swift`
- [ ] **[P1]** 内部 padding 从 16 改为 20，与其他卡片统一
- [ ] **[P2]** Sparkline 折线宽度从 1.5 增至 2.0，在 Retina 屏上更清晰
- [ ] **[P2]** 空状态的 plus.circle.dashed 图标可增加 `primary.opacity(0.4)` 的径向渐变背景圈

#### `StreakCard.swift`
- [ ] **[P1]** 内部 padding 从 16 改为 20，与其他卡片统一
- [ ] **[P2]** Divider 使用系统默认样式，可替换为 `AppTheme.Colors.divider` 色的 1pt 线，Dark Mode 自适应
- [ ] **[P2]** 火焰图标阴影 `Color(hex: "#FF6B35").opacity(0.4)` 偏浓，建议 `0.25`

#### `ActivityCalendar.swift`
- [ ] **[P1]** 日期圆形的非活跃背景 `Color.gray.opacity(0.06)` 在 Dark Mode 下需提高至 `0.1`
- [ ] **[P2]** 活跃日圆形的 `shadow(radius: 3)` 跟随全局阴影优化

#### `IntakeChartCard.swift` (未详细阅读)
- [ ] **[P2]** 确认是否有硬编码颜色和缺失 `.continuous` 圆角的问题

### 3.6 Analysis 页

#### `AnalysisView.swift`
- [ ] **[P0]** 内容区 `.background(Color.white)` 改为 `Color(.systemBackground)` 适配 Dark Mode
- [ ] **[P1]** `UnevenRoundedRectangle` 添加 `.continuous` 圆角风格（如果 API 支持）
- [ ] **[P1]** 拖拽指示条颜色 `AppTheme.Colors.dragIndicator` 需确认 Dark Mode 可见性
- [ ] **[P2]** 食物编辑 Sheet 中的输入框 `Color(.systemGray6)` 已使用系统色，clipShape 的 `RoundedRectangle(cornerRadius: 12)` 需添加 `.continuous`

### 3.7 Camera 页 (需审查)
- [ ] **[P2]** 确认 ShutterButton, AIHintBadge, FocusReticle 等组件的圆角和颜色适配

---

## 四、执行优先级总结

### Phase 1: 暗黑模式 & 圆角 (P0) — 基础体验保障

1. Asset Catalog Color Sets 创建（Dark Mode 全色彩适配）
2. 所有 `RoundedRectangle` 添加 `style: .continuous`
3. `premiumBackground()` Dark Mode 渐变
4. `AnalysisView` 白色背景修复

### Phase 2: 色彩微调 & 排版收拢 (P1) — 视觉品质跃升

5. 主色调优化（`#13EC5B` → 更温润的绿色）
6. Typography Scale 收拢为 7 档
7. 散落字号全局统一替换
8. 间距和 padding 全局统一
9. 阴影系统重建
10. 圆角阶梯重新校准

### Phase 3: 细节打磨 (P2) — 精致度提升

11. 数字 tracking 微调
12. 组件级视觉细节优化
13. 进度条/光效参数微调
14. Camera 页组件审查

---

## 五、注意事项

1. **不修改任何业务逻辑**: 本计划仅涉及视觉层代码
2. **逐步验证**: 每完成一个 Phase 在真机上验证 Light/Dark 两种模式
3. **保持 Accessibility 兼容性**: 颜色调整后需确认对比度 ≥ 4.5:1 (WCAG AA)
4. **性能关注**: `premiumBackground()` 已使用 `.drawingGroup()`，新增渐变不要破坏此优化
5. **向后兼容**: `Jakarta` 命名空间的兼容层在排版重构后可标记为 `@available(*, deprecated)` 但暂不移除
