# FoodMoment 开发计划（iOS 原生版）

> 🍽️ 一款通过 AI 拍照识别食物卡路里并记录饮食的 iOS 应用  
> 基于 Google Stitch 原型图设计 · 平台：iOS 17+

---

## 一、产品概览

### 1.1 产品定位
FoodMoment 是一款面向健康饮食管理的 **iOS 原生 App**，核心功能是通过 **AI 拍照识别食物**，自动分析卡路里和营养成分（蛋白质、碳水、脂肪），并以精美的时间线方式记录每日饮食。

### 1.2 为什么选择 iOS 原生（而非 Flutter）

| 维度 | iOS 原生优势 |
|------|-------------|
| **相机体验** | AVFoundation 提供最底层的相机控制，零延迟取景、实时预览帧处理 |
| **AI/ML** | Core ML + Vision 框架可在设备端运行食物识别，无需联网、响应更快、隐私合规 |
| **UI 表现力** | SwiftUI 原生支持 `.ultraThinMaterial`（毛玻璃）、`spring` 动画、`Canvas` 自绘 |
| **健康数据** | HealthKit 直连，无需第三方桥接，步数/体重/营养数据无缝读写 |
| **系统集成** | Live Activity、Widget、Spotlight 搜索、Shortcuts、iCloud 同步 |
| **性能** | 原生渲染无桥接开销，动画帧率稳定 60/120fps（ProMotion） |
| **包体积** | ~15MB（Flutter ~30-50MB），用户下载意愿更强 |
| **App Store 审核** | 原生应用通过率更高，审核周期更短 |
| **第三方依赖** | 极少——Apple 原生框架覆盖 90% 需求（SwiftData、Swift Charts、Vision、HealthKit） |

### 1.3 核心页面（来自原型图）

| 页面 | 原型文件 | 功能描述 |
|------|---------|---------|
| 🏠 首页仪表盘 | `foodmoment_home_dashboard_3` | 每日卡路里环形图、宏量营养素、饮水/步数追踪、今日食刻卡片流 |
| 📸 拍照识别 | `camera_interface` | 全屏取景器、AI 辅助提示、Scan/Barcode/History 模式切换 |
| 🔬 分析结果 | `analysis_result` | 食物标注（目标检测）、总热量、三大营养素环形图、AI 分析建议、记录饮食 |
| 📖 饮食日记 | `foodmoment_home_dashboard_1` | 时间线式食物日记、按日期浏览、每日达标进度 |
| 📊 统计洞察 | `foodmoment_home_dashboard_2/3` | 周/月/年趋势图、宏量营养素同心圆图、打卡一致性、AI Insight |
| 👤 个人中心 | `profile_&_history` | 用户档案、体重追踪、连续打卡、活动日历、成就勋章、摄入趋势 |

### 1.4 导航结构（Tab Bar）
```
Home | Stats | ➕ Scan(Camera) | Log(Diary) | Profile
```

---

## 二、技术选型

### 2.1 iOS 客户端技术栈

| 组件 | 技术选型 | 说明 |
|------|---------|------|
| **UI 框架** | SwiftUI (iOS 17+) | 声明式 UI，原生毛玻璃/动画/手势支持 |
| **架构模式** | MVVM + Repository | `@Observable` macro（Swift 5.9），结构清晰 |
| **并发模型** | Swift Concurrency | `async/await`、`Actor`、`TaskGroup` |
| **相机** | AVFoundation | 自定义取景器、实时帧处理、Photo Capture |
| **AI/ML（端侧）** | Core ML + Vision | 设备端食物识别，隐私优先，ANE 加速 |
| **AI/ML（云端）** | Gemini Vision API / GPT-4o | 高精度多模态分析，营养估算 |
| **条形码** | Vision `VNDetectBarcodesRequest` | 系统原生条形码扫描 |
| **健康数据** | HealthKit | 步数、体重、营养数据读写 |
| **本地存储** | SwiftData (iOS 17) | Apple 原生 ORM，替代 Core Data |
| **网络层** | URLSession + async/await | 原生网络请求，配合 Codable 解析 |
| **图片缓存** | Kingfisher | 高性能图片加载与缓存 |
| **图表** | Swift Charts (iOS 16+) | Apple 原生图表框架 |
| **动画** | SwiftUI Animation | `withAnimation(.spring())`、`PhaseAnimator`、`keyframeAnimator` |
| **推送** | APNs + UserNotifications | 用餐/打卡提醒 |
| **云同步** | CloudKit | iCloud 多设备同步 |
| **Widget** | WidgetKit | 桌面小组件展示今日卡路里 |

### 2.2 最低系统要求

| 要求 | 版本 |
|------|------|
| iOS | 17.0+ |
| Xcode | 16.0+ |
| Swift | 5.9+ |
| 设备 | iPhone（iPad 后续支持） |

> 选择 iOS 17+ 是为了使用 `@Observable` macro、SwiftData、新的 `ScrollView` API、交互式 Widget 和 `contentTransition(.numericText())`。

### 2.3 后端服务

| 组件 | 技术选型 | 说明 |
|------|---------|------|
| API 服务 | **Python FastAPI** | 高性能异步框架，AI/ML 生态无缝集成 |
| 数据库 | **PostgreSQL** + **Redis** | 结构化数据存储 + 缓存 |
| 对象存储 | **AWS S3 / 阿里云 OSS** | 存储用户拍摄的食物照片 |
| 认证 | **Sign in with Apple** + JWT | iOS 首选 Apple 登录（App Store 要求） |
| BaaS 备选 | **Supabase / CloudKit** | 快速上线可用 BaaS 方案 |

### 2.4 AI / ML 能力

| 能力 | 技术方案 | 说明 |
|------|---------|------|
| 食物识别（端侧） | **Core ML** + CreateML / coremltools 转换 YOLOv8 | 离线可用，隐私合规，< 100ms 响应 |
| 食物识别（云端） | **Gemini Vision API** / **GPT-4o** | 高精度多模态，复杂中餐识别 |
| 营养估算 | **LLM + USDA FoodData Central** | 云端 LLM 估算 + 标准数据库校准 |
| 条形码 | **Vision** `VNDetectBarcodesRequest` | 系统原生，无需第三方 SDK |
| AI 洞察 | **LLM (GPT-4 / Claude)** | 生成个性化饮食建议 |
| 端侧加速 | **Apple Neural Engine (ANE)** | Core ML 自动利用 ANE，功耗极低 |

### 2.5 双阶段识别策略

```
拍照 → [阶段1: 端侧 Core ML] → 0.1s 内返回初步识别结果（食物名 + 位置框）
                ↓
      [阶段2: 云端 Gemini/GPT-4o] → 1-3s 返回精细营养分析 + AI 建议
                ↓
      合并结果 → 展示分析页面
```

> 阶段 1 保证离线可用 + 即时反馈；阶段 2 提供深度分析。用户在等待云端结果时已能看到初步标注。

### 2.6 设计系统（从原型提取）

```
品牌色:
  Primary:      Color(hex: "#13EC5B")   // 活力绿
  Background:   Color(hex: "#F8F9FA")   // .systemGroupedBackground 
  Dark BG:      Color(hex: "#102216")

SwiftUI 毛玻璃:
  .ultraThinMaterial   // 相机覆盖按钮
  .regularMaterial     // 底部导航、浮窗
  .thickMaterial       // Bottom Sheet

字体:
  英文: Plus Jakarta Sans (.custom("PlusJakartaSans", size:))
  中文: .system(design: .default) → PingFang SC 自动回退

圆角:
  .small   = 16   // 标签、小按钮
  .medium  = 24   // 普通卡片
  .large   = 32   // 大卡片、Bottom Sheet
  .capsule         // 胶囊按钮

阴影:
  .glass   = .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
  .glow    = .shadow(color: .green.opacity(0.4), radius: 15)
  .card    = .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
```

---

## 三、功能模块拆分与开发计划

### Phase 1：基础架构与核心拍照识别（第 1-4 周）

#### Sprint 1（第 1-2 周）：项目初始化 & 基础框架

| 任务 | 详情 | 优先级 |
|------|------|--------|
| Xcode 项目创建 | SwiftUI App 模板，Bundle ID、签名证书、Capabilities（HealthKit、Camera、Push） | P0 |
| 架构搭建 | MVVM + Repository 分层，建立 Features/ Core/ Models/ 目录 | P0 |
| 设计系统实现 | `AppTheme.swift` 品牌色/字体/圆角；`GlassCard` 毛玻璃 ViewModifier | P0 |
| 自定义 Tab 导航 | 自定义 `CustomTabBar`：5 个 Tab + 中间凸起扫描按钮（原型浮动 TabBar） | P0 |
| SwiftData 配置 | `ModelContainer` 初始化，定义所有 `@Model` 数据模型 | P0 |
| 网络层封装 | `APIClient`：URLSession + async/await + Codable + 错误处理 | P0 |
| Sign in with Apple | `AuthenticationServices` 实现登录 + 后端 JWT 验证 | P0 |
| 后端初始化 | FastAPI 项目搭建、PostgreSQL 模型、Docker Compose | P0 |

**交付物：** 可运行的 App 骨架，含 5-Tab 导航和 Apple 登录

#### Sprint 2（第 3-4 周）：📸 相机与 AI 识别

| 任务 | 详情 | 优先级 |
|------|------|--------|
| AVFoundation 相机 | `AVCaptureSession` + `AVCaptureVideoPreviewLayer`，通过 `UIViewRepresentable` 嵌入 SwiftUI | P0 |
| 全屏取景器 | 黑色背景 + 相机预览全屏 + 渐变遮罩 Overlay（上下渐黑） | P0 |
| 对焦框 | 四角 L 型白色半透明边框 + 中心绿色十字，`withAnimation(.spring())` | P1 |
| 快门按钮 | 外圈 4px 绿色描边 + 内圈 66pt 白色圆，`.scaleEffect` 按压动画 | P0 |
| 闪光灯切换 | `AVCaptureDevice.torchMode` on/off/auto | P1 |
| AI 提示条 | 毛玻璃胶囊 "Keep steady for better accuracy" + 脉冲 `.opacity` 动画 | P1 |
| 模式切换 | 底部 Scan / Barcode / History 文字切换，当前绿色高亮 | P0 |
| 拍照 | `AVCapturePhotoOutput` → 压缩 JPEG → 预览确认 | P0 |
| 相册选择 | `PhotosPicker`（SwiftUI 原生 iOS 16+）选择已有照片 | P0 |
| 相册缩略图 | 左下角显示最近一张照片的圆角缩略图 | P1 |
| 图片上传 | 上传至 OSS → 返回 URL | P0 |
| Core ML 集成 | 食物识别 `.mlmodel` 部署，Vision `VNCoreMLRequest` 推理 | P0 |
| 云端识别 API | 后端接收图片 → Gemini Vision → 返回食物 + 营养结果 | P0 |
| 条形码扫描 | `VNDetectBarcodesRequest` 实时帧分析 → 查询食品数据库 | P1 |

**交付物：** 可拍照识别食物并返回卡路里数据

---

### Phase 2：分析结果 & 饮食记录（第 5-8 周）

#### Sprint 3（第 5-6 周）：🔬 分析结果页

| 任务 | 详情 | 优先级 |
|------|------|--------|
| 全屏食物照片 | 拍摄照片作为背景 + `LinearGradient` 遮罩（上方暗→中间透明→下方暗） | P0 |
| 食物标注浮层 | 在照片对应位置叠加毛玻璃标签：彩色圆点 + Emoji + 名称 | P0 |
| 连线 + 定位点 | 标签下方 1px 白线 + 底部白色小圆发光点 | P0 |
| 标签出场动画 | `.transition(.scale.combined(with: .opacity))` + 依次延时出现 | P1 |
| 顶部控制栏 | 毛玻璃圆形关闭按钮 + 分享按钮 | P0 |
| Bottom Sheet | `.sheet` with `presentationDetents([.medium, .large])` | P0 |
| 拖拽指示条 | 顶部居中 12×1.5 灰色圆角条 | P0 |
| 总热量展示 | "TOTAL ENERGY" 小字 + "485 kcal" 超大粗体居中 | P0 |
| 三大营养素圆环 | 三个并排的 `Circle().trim(from:to:)` + 中心数值 + 底部标签 | P0 |
| 圆环进度动画 | `withAnimation(.easeOut(duration: 1))` 从 0 动画到目标值 | P1 |
| AI 分析卡片 | 绿色渐变边框 + `auto_awesome` 图标 + "AI Analysis" + 建议文字 | P1 |
| Log Meal 按钮 | 全宽绿色胶囊按钮，绿色发光阴影，按下 `.scaleEffect(0.95)` | P0 |
| 保存到 SwiftData | 创建 `MealRecord` + 关联 `DetectedFood` 列表 | P0 |
| 同步到后端 | 异步上传记录到服务器 | P0 |
| HealthKit 写入 | `.dietaryEnergyConsumed`、`.dietaryProtein` 等写入 | P1 |
| 手动编辑 | 点击标签弹出编辑框，修改食物名/份量/卡路里 | P1 |
| 分享 | `ShareLink` + `ImageRenderer` 渲染结果为图片 | P2 |

**交付物：** 完整的拍照 → 识别 → 分析 → 记录流程

#### Sprint 4（第 7-8 周）：📖 饮食日记

| 任务 | 详情 | 优先级 |
|------|------|--------|
| 页面结构 | `ScrollView` + sticky header（月份 + 日期选择器） | P0 |
| 时间线布局 | `LazyVStack` 左侧：竖线 `Rectangle(width:1)` + 圆点节点 | P0 |
| 食物大图卡片 | 圆角 24pt 图片 + 左上毛玻璃餐次标签 + 右下卡路里角标 | P0 |
| 餐次标签样式 | 彩色小圆点（早餐黄/午餐橙/加餐蓝）+ 时间文字 | P0 |
| 卡片交互 | 点击进入详情页、`.swipeActions` 左滑删除/编辑 | P0 |
| 水平日期选择器 | `ScrollView(.horizontal)` 7 天选择器，当天圆形黑底白字高亮 | P0 |
| 绿色指示点 | 有记录的日期底部显示绿色小圆点 | P1 |
| 月份标题 | "2023年10月" + 下拉箭头，点击弹出 `.menu` 月份选择 | P1 |
| 搜索 & 日历 | 顶部搜索 + 日历图标按钮 | P1 |
| 食物描述 | 名称（粗体）+ 描述文字（灰色）+ 营养标签（`#高蛋白 #低GI`） | P1 |
| 每日达标浮窗 | 底部固定毛玻璃卡："本日已达标 85%" + 绿色进度条 | P0 |
| 空状态 | 无记录时显示引导插画 + "拍照记录第一餐" 按钮 | P1 |
| SwiftData 查询 | `@Query(filter: #Predicate { ... }, sort: \.mealTime)` 按日期过滤 | P0 |
| `.searchable` | 搜索历史食物记录 | P2 |

**交付物：** 完整的饮食日记浏览与管理

---

### Phase 3：首页仪表盘 & 统计（第 9-12 周）

#### Sprint 5（第 9-10 周）：🏠 首页仪表盘

| 任务 | 详情 | 优先级 |
|------|------|--------|
| 问候语 Header | 根据 `Calendar.current.component(.hour)` 显示"早安/午好/晚好，{名}" | P0 |
| 头像 + PRO | 右上圆形头像，右下绿色 "PRO" 角标 | P0 |
| 三层卡路里环形图 | 嵌套 `Circle().trim()` × 3 层：热量(深绿→墨绿) / 蛋白质(黄绿) / 碳水(米白→薄荷) | P0 |
| 渐变描边 | `.stroke(LinearGradient(colors: [...], ...), lineWidth: 14)` | P0 |
| 底圈灰色轨道 | 三个 `Circle().stroke(Color.gray.opacity(0.1), lineWidth: 14)` 作底 | P0 |
| 中心数字 | "1,240" 超大粗体 + "KCAL LEFT" 小字，`.contentTransition(.numericText())` 数字变化动画 | P0 |
| 底部指标行 | 三个毛玻璃小卡：彩色圆点 + 名称 + 当前值（热量 850 / 蛋白质 45g / 碳水 120g） | P0 |
| "每日目标: 2,500" | 圆环下方灰色小字 | P0 |
| 毛玻璃大卡片 | 整个环形图区域包裹在 `.background(.ultraThinMaterial)` 圆角卡内 | P0 |
| 饮水量卡片 | 水滴图标 + 1,250 mL + 进度条，右上 "+" 按钮点击 +250mL | P1 |
| 步数卡片 | HealthKit `HKQuantityType(.stepCount)` 读取 + 进度条 | P1 |
| 两卡并排 | `LazyVGrid(columns: [.flexible(), .flexible()])` 双列布局 | P0 |
| 今日食刻标题 | "今日食刻" + "View All" 链接 | P0 |
| 食刻横滑卡片 | `ScrollView(.horizontal)` + `.scrollTargetBehavior(.viewAligned)` snap 对齐 | P0 |
| 卡片样式 | 64×80 圆角大图 + 底部渐变遮罩 + 餐次 + 名称 + kcal 角标 + 编辑按钮 | P0 |
| 下拉刷新 | `.refreshable { await viewModel.refresh() }` | P1 |

**交付物：** 精美的首页仪表盘

#### Sprint 6（第 11-12 周）：📊 统计洞察

| 任务 | 详情 | 优先级 |
|------|------|--------|
| 页面 Header | "Statistics" 大标题 + "Overview & Trends" 副标题 + 日历按钮 | P0 |
| 时间范围选择器 | `Picker(selection:) { }.pickerStyle(.segmented)` 日/周/月/年 | P0 |
| 卡路里趋势图 | Swift Charts `LineMark` + `AreaMark` (渐变填充) + `PointMark` 数据点 | P0 |
| 图表交互 | `.chartOverlay { proxy in ... }` 点击/拖动高亮数据点 | P1 |
| 周平均统计 | "Weekly Average 2,140 kcal" + 绿色 "+12%" 环比变化 badge | P0 |
| 宏量营养素同心环 | 三层 `Circle().trim()` 不同半径：蛋白质(蓝) / 碳水(黄) / 脂肪(红) | P0 |
| 环形图图例 | 右侧竖排：彩色圆点 + 名称 + 克数 | P0 |
| 打卡一致性网格 | `LazyVGrid(columns: 7)` 14 天圆形：绿色(已打卡)/灰色(未打卡) | P1 |
| AI Insight 卡片 | 深色渐变圆角卡 (`from: .slate900 to: .slate800`) + 灯泡图标 + LLM 建议文字 | P1 |
| 数据聚合 API | 后端按日/周/月聚合 kcal + 营养素 | P0 |
| 切换动画 | `.animation(.easeInOut, value: selectedRange)` 切换时间范围时平滑过渡 | P1 |
| 数据导出 | 生成 CSV → `ShareLink` 分享 | P2 |

**交付物：** 可视化统计分析与 AI 洞察

---

### Phase 4：个人中心 & 高级功能（第 13-16 周）

#### Sprint 7（第 13-14 周）：👤 个人中心

| 任务 | 详情 | 优先级 |
|------|------|--------|
| 头像区域 | 渐变边框圆形头像（`.overlay(Circle().stroke(gradient))`) + PRO 角标 | P0 |
| 用户名 | 大号粗体居中 | P0 |
| 体重追踪卡 | 毛玻璃卡：当前体重 68kg + 目标 65kg + 趋势 "↓ 0.5kg" 绿色 badge + 进度条 | P0 |
| 体重记录 | HealthKit 读写 `HKQuantityType(.bodyMass)` + 手动输入 | P0 |
| 连续打卡卡 | 毛玻璃卡：🔥 火焰图标 + "12 Days" + 激励文案 | P0 |
| 活动日历 | 月度 7×5 网格日历，每天用三层环形小图表示当日三大营养素达标率 | P1 |
| 月份切换 | "< October >" 左右切换 | P1 |
| 成就勋章 | `ScrollView(.horizontal)` 金/银/铜 3D 风格勋章 | P1 |
| 勋章样式 | 径向渐变圆形 + Material Symbols 图标 + 底部 tier 标签 | P1 |
| 平均摄入卡片 | 毛玻璃卡内：大数字 "1,850 kcal" + "-5% vs 上周" + 柱状图 + 折线图叠加 | P1 |
| 设置页 | `Form { Section { } }` 实现通知/单位/深色模式/语言/隐私/注销账户 | P0 |
| 删除账户 | App Store 要求：必须提供账户删除入口 | P0 |
| App Icon | 设计品牌 App Icon 并配置 Asset Catalog | P0 |

**交付物：** 完整的个人中心页

#### Sprint 8（第 15-16 周）：🚀 高级功能与 iOS 生态集成

| 任务 | 详情 | 优先级 |
|------|------|--------|
| Widget 小组件 | WidgetKit：小/中尺寸 Widget，展示今日卡路里环形图 + 剩余量 | P1 |
| 快捷扫描 Widget | 中尺寸 Widget 含 "Scan" 快捷入口（Deep Link 打开相机） | P1 |
| Live Activity | 正在记录餐食时灵动岛 / 锁屏展示进度（iOS 16.1+） | P2 |
| Spotlight 索引 | `CSSearchableIndex` 将食物记录编入系统搜索 | P2 |
| Siri Shortcuts | `AppIntent` 实现 "记录早餐"、"今日卡路里" 等指令 | P2 |
| 手动食物搜索 | 搜索框 + 自动补全（USDA + 自建中文库） | P1 |
| 饮水追踪完善 | 自定义杯量 (250/500/750mL)，写入 HealthKit `.dietaryWater` | P1 |
| 推送通知 | `UNUserNotificationCenter`：用餐提醒(8:00/12:00/18:00)、打卡提醒(21:00) | P1 |
| iCloud 同步 | SwiftData + CloudKit 容器，多设备自动同步 | P2 |
| 离线支持 | SwiftData 本地全量存储 + `isSynced` 标记 + 网络恢复后 `TaskGroup` 批量上传 | P1 |
| 性能优化 | `LazyVStack` 懒加载、`AsyncImage` 缩略图、Instruments 内存/GPU 调优 | P1 |
| 无障碍 | `.accessibilityLabel()` / `.accessibilityValue()` + Dynamic Type 适配 | P1 |

**交付物：** 功能完备 + 深度融入 iOS 生态

---

### Phase 5：上线准备（第 17-20 周）

#### Sprint 9（第 17-18 周）：打磨 & 测试

| 任务 | 详情 |
|------|------|
| UI 打磨 | 逐像素对齐原型：动画曲线参数、阴影偏移、间距微调、字重 |
| 深色模式 | 全面适配：`.background(Color(.systemBackground))` + 原型暗色值 `#102216` |
| 国际化 | `String(localized:)` + `.xcstrings` 中英双语 |
| 单元测试 | XCTest 核心 ViewModel / Repository 逻辑，覆盖率 > 80% |
| UI 测试 | XCUITest 关键流程：拍照 → 识别 → 记录 → 日记 → 统计 |
| Snapshot 测试 | 关键页面截图回归（Light + Dark） |
| 性能检测 | Instruments：Time Profiler、Allocations、Core Animation、Energy Log |
| 内存泄漏 | Instruments Leaks + Zombie Objects 检查 |

#### Sprint 10（第 19-20 周）：上线

| 任务 | 详情 |
|------|------|
| App Store Connect | 配置 App 信息、年龄分级（4+）、类别（健康健美） |
| 截图准备 | 6.7" (iPhone 15 Pro Max) + 6.1" (iPhone 15 Pro) 至少各 5 张 |
| App Preview | 30 秒演示视频（可选但推荐） |
| 隐私标签 | 准确填写 App Privacy：相机、照片、HealthKit、网络使用说明 |
| 隐私政策 | 网页版隐私政策 + 使用条款 URL |
| TestFlight 内测 | 邀请 100+ 种子用户，收集反馈 2 周 |
| Bug 修复 | 内测反馈问题快速修复 |
| 审核提交 | Submit for Review，预留 1-3 天审核周期 |
| 监控部署 | Sentry iOS SDK 崩溃监控 + 后端 APM |
| **🎉 正式上线** | App Store 发布 |

---

## 四、项目目录结构（Xcode / SwiftUI）

```
FoodMoment/
├── FoodMoment.xcodeproj
├── FoodMoment/
│   ├── App/
│   │   ├── FoodMomentApp.swift            # @main 入口 + ModelContainer
│   │   ├── ContentView.swift              # Root: 登录判断 + TabView
│   │   └── AppState.swift                 # @Observable 全局状态
│   │
│   ├── Core/
│   │   ├── Theme/
│   │   │   ├── AppTheme.swift             # 颜色/字体/圆角/阴影常量
│   │   │   ├── Color+Brand.swift          # extension Color { static let primary... }
│   │   │   └── Font+Custom.swift          # Plus Jakarta Sans 注册与使用
│   │   ├── Network/
│   │   │   ├── APIClient.swift            # URLSession async/await + interceptor
│   │   │   ├── APIEndpoint.swift          # enum 端点定义
│   │   │   ├── APIError.swift             # 错误类型
│   │   │   └── TokenManager.swift         # Keychain JWT 管理
│   │   ├── Storage/
│   │   │   └── PersistenceController.swift # ModelContainer 配置
│   │   ├── HealthKit/
│   │   │   └── HealthKitManager.swift     # Actor: HealthKit 授权 + 读写
│   │   ├── Camera/
│   │   │   └── CameraService.swift        # Actor: AVCaptureSession 管理
│   │   ├── ML/
│   │   │   └── FoodClassifierService.swift # Core ML + Vision 推理
│   │   └── Extensions/
│   │       ├── View+Glass.swift           # .glassCard() modifier
│   │       ├── View+Shimmer.swift         # 骨架屏加载
│   │       └── Date+Helpers.swift         # 日期格式化工具
│   │
│   ├── Models/
│   │   ├── MealRecord.swift               # @Model
│   │   ├── DetectedFood.swift             # @Model
│   │   ├── UserProfile.swift              # @Model
│   │   ├── WeightLog.swift                # @Model
│   │   ├── WaterLog.swift                 # @Model
│   │   ├── Achievement.swift              # @Model
│   │   └── DTOs/
│   │       ├── AnalysisResponse.swift     # Codable API 响应
│   │       ├── NutritionData.swift        # 营养数据
│   │       └── FoodSearchResult.swift     # 搜索结果
│   │
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── AuthViewModel.swift
│   │   │   └── SignInView.swift
│   │   │
│   │   ├── Home/
│   │   │   ├── HomeViewModel.swift
│   │   │   ├── HomeView.swift
│   │   │   └── Components/
│   │   │       ├── CalorieRingChart.swift
│   │   │       ├── MacroIndicatorRow.swift
│   │   │       ├── WaterCard.swift
│   │   │       ├── StepsCard.swift
│   │   │       └── FoodMomentCarousel.swift
│   │   │
│   │   ├── Camera/
│   │   │   ├── CameraViewModel.swift
│   │   │   ├── CameraView.swift
│   │   │   ├── CameraPreviewView.swift    # UIViewRepresentable
│   │   │   └── Components/
│   │   │       ├── FocusReticle.swift
│   │   │       ├── ShutterButton.swift
│   │   │       ├── ModeSelector.swift
│   │   │       ├── AIHintBadge.swift
│   │   │       └── GalleryThumbnail.swift
│   │   │
│   │   ├── Analysis/
│   │   │   ├── AnalysisViewModel.swift
│   │   │   ├── AnalysisView.swift
│   │   │   └── Components/
│   │   │       ├── FoodTagOverlay.swift
│   │   │       ├── FoodTagPin.swift
│   │   │       ├── NutritionRing.swift
│   │   │       ├── NutritionRingsRow.swift
│   │   │       ├── AIInsightCard.swift
│   │   │       └── LogMealButton.swift
│   │   │
│   │   ├── Diary/
│   │   │   ├── DiaryViewModel.swift
│   │   │   ├── DiaryView.swift
│   │   │   └── Components/
│   │   │       ├── TimelineEntry.swift
│   │   │       ├── WeekDatePicker.swift
│   │   │       ├── DailyProgressFloat.swift
│   │   │       └── FoodPhotoCard.swift
│   │   │
│   │   ├── Statistics/
│   │   │   ├── StatisticsViewModel.swift
│   │   │   ├── StatisticsView.swift
│   │   │   └── Components/
│   │   │       ├── CalorieTrendChart.swift
│   │   │       ├── MacroDonutChart.swift
│   │   │       ├── CheckinGrid.swift
│   │   │       ├── TimeRangeSelector.swift
│   │   │       └── AIInsightDarkCard.swift
│   │   │
│   │   └── Profile/
│   │       ├── ProfileViewModel.swift
│   │       ├── ProfileView.swift
│   │       ├── SettingsView.swift
│   │       └── Components/
│   │           ├── WeightCard.swift
│   │           ├── StreakCard.swift
│   │           ├── ActivityCalendar.swift
│   │           ├── AchievementBadge.swift
│   │           └── IntakeChartCard.swift
│   │
│   ├── SharedComponents/
│   │   ├── GlassCard.swift                # .background(.ultraThinMaterial)
│   │   ├── CustomTabBar.swift             # 自定义底部导航栏
│   │   ├── GradientButton.swift           # 大号操作按钮
│   │   ├── RingShape.swift                # 可复用 Shape
│   │   └── EmptyStateView.swift           # 空状态占位
│   │
│   └── Resources/
│       ├── Assets.xcassets/               # 图片 & App Icon
│       ├── Fonts/
│       │   ├── PlusJakartaSans-Regular.ttf
│       │   ├── PlusJakartaSans-Medium.ttf
│       │   ├── PlusJakartaSans-SemiBold.ttf
│       │   ├── PlusJakartaSans-Bold.ttf
│       │   └── PlusJakartaSans-ExtraBold.ttf
│       ├── Localizable.xcstrings          # 国际化
│       ├── Info.plist                     # 权限描述
│       └── FoodClassifier.mlmodel         # Core ML 模型
│
├── FoodMomentWidget/                      # WidgetKit Target
│   ├── FoodMomentWidgetBundle.swift
│   ├── CalorieRingWidget.swift
│   └── QuickScanWidget.swift
│
├── FoodMomentTests/                       # XCTest
│   ├── ViewModels/
│   ├── Services/
│   └── Mocks/
│
├── FoodMomentUITests/                     # XCUITest
│   └── FlowTests/
│
└── README.md
```

---

## 五、后端 API 设计

### 5.1 核心端点

```
认证
POST   /api/v1/auth/apple             # Sign in with Apple 验证
POST   /api/v1/auth/refresh            # 刷新 Token
DELETE /api/v1/auth/account            # 注销账户（App Store 强制要求）

食物识别
POST   /api/v1/food/analyze            # 上传图片 → AI 识别 → 返回食物 & 营养
GET    /api/v1/food/barcode/{code}     # 条形码查询
GET    /api/v1/food/search?q=          # 食物搜索

饮食记录
POST   /api/v1/meals                   # 记录一餐
GET    /api/v1/meals?date=2026-02-09   # 查询某日饮食
PUT    /api/v1/meals/{id}              # 编辑
DELETE /api/v1/meals/{id}              # 删除

统计
GET    /api/v1/stats/daily?date=       # 每日统计
GET    /api/v1/stats/weekly?week=      # 每周统计
GET    /api/v1/stats/monthly?month=    # 每月统计
GET    /api/v1/stats/insights          # AI 洞察

用户
GET    /api/v1/user/profile            # 资料
PUT    /api/v1/user/profile            # 更新
GET    /api/v1/user/achievements       # 成就
PUT    /api/v1/user/goals              # 目标
POST   /api/v1/user/weight             # 记录体重
GET    /api/v1/user/streaks            # 打卡
DELETE /api/v1/user/account            # 删除账户（GDPR）

饮水
POST   /api/v1/water                   # 记录
GET    /api/v1/water?date=             # 查询
```

### 5.2 食物识别 API 响应

```json
{
  "image_url": "https://oss.example.com/food/abc123.jpg",
  "total_calories": 485,
  "total_nutrition": {
    "protein_g": 22,
    "carbs_g": 45,
    "fat_g": 18,
    "fiber_g": 6
  },
  "detected_foods": [
    {
      "name": "Poached Egg",
      "name_zh": "水波蛋",
      "emoji": "🥚",
      "confidence": 0.95,
      "bounding_box": { "x": 0.55, "y": 0.15, "w": 0.2, "h": 0.15 },
      "calories": 140,
      "color": "#FACC15"
    },
    {
      "name": "Avocado",
      "name_zh": "牛油果",
      "emoji": "🥑",
      "confidence": 0.92,
      "bounding_box": { "x": 0.10, "y": 0.30, "w": 0.25, "h": 0.2 },
      "calories": 160,
      "color": "#4ADE80"
    }
  ],
  "ai_analysis": "营养均衡的一餐！牛油果提供优质脂肪，鸡蛋富含蛋白质，适合运动后恢复。",
  "tags": ["高蛋白", "低GI", "优质脂肪"]
}
```

---

## 六、SwiftData 数据模型

```swift
import SwiftData
import Foundation

@Model final class UserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var avatarURL: String?
    var isPro: Bool = false
    var dailyCalorieGoal: Int = 2000
    var dailyProteinGoal: Int = 50
    var dailyCarbsGoal: Int = 250
    var dailyFatGoal: Int = 65
    var targetWeight: Double?
    var createdAt: Date = Date()
}

@Model final class MealRecord {
    @Attribute(.unique) var id: UUID
    var imageURL: String?
    @Attribute(.externalStorage) var localImageData: Data?
    var mealType: String           // breakfast / lunch / dinner / snack
    var mealTime: Date
    var totalCalories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double
    var fiberGrams: Double
    var title: String
    var descriptionText: String?
    var aiAnalysis: String?
    var tags: [String]
    var isSynced: Bool = false
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade)
    var detectedFoods: [DetectedFood] = []
}

@Model final class DetectedFood {
    @Attribute(.unique) var id: UUID
    var name: String
    var nameZh: String
    var emoji: String
    var confidence: Double
    var boundingBoxX: Double
    var boundingBoxY: Double
    var calories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double
    var mealRecord: MealRecord?
}

@Model final class WeightLog {
    @Attribute(.unique) var id: UUID
    var weightKg: Double
    var recordedAt: Date
    var createdAt: Date = Date()
}

@Model final class WaterLog {
    @Attribute(.unique) var id: UUID
    var amountML: Int
    var recordedAt: Date = Date()
}

@Model final class Achievement {
    @Attribute(.unique) var id: UUID
    var type: String           // streak_7day, veggie_king, early_bird
    var tier: String           // gold, silver, bronze
    var earnedAt: Date
}
```

---

## 七、iOS 特有技术要点

| 挑战 | SwiftUI / iOS 解决方案 |
|------|----------------------|
| AVFoundation in SwiftUI | `UIViewRepresentable` 包装 `AVCaptureVideoPreviewLayer`，ViewModel 用 `Actor` 管理 session |
| Core ML 模型准备 | CreateML 训练 或 `coremltools` 将 YOLOv8 ONNX → `.mlmodel` |
| 双阶段识别 | 端侧 Core ML 快速出框 → 云端 Gemini 精细分析（并行 Task） |
| 毛玻璃效果 | `.background(.ultraThinMaterial)` + `.clipShape(RoundedRectangle(cornerRadius:))` |
| 环形图 | `Circle().trim(from: 0, to: progress).stroke(gradient, lineWidth:)` + `withAnimation` |
| 自定义 Tab Bar | 隐藏系统 `.toolbar(.hidden, for: .tabBar)`，ZStack 底层放 `CustomTabBar` |
| HealthKit 权限 | `HKHealthStore().requestAuthorization()` + Info.plist 两个 key |
| 数字动画 | `.contentTransition(.numericText())` iOS 17 原生数字变化动画 |
| 离线同步 | SwiftData 本地存 + `isSynced` + `NWPathMonitor` 网络恢复后 batch sync |
| App Store 审核 | 删除账户入口 + 隐私标签 + 权限用途说明 |

---

## 八、Swift Package 依赖（极简）

```
✅ Apple 原生框架（零额外依赖）:
   SwiftUI / SwiftData / Swift Charts / AVFoundation
   Vision / Core ML / HealthKit / WidgetKit / CloudKit
   PhotosUI / AuthenticationServices / UserNotifications

📦 第三方（仅 2-3 个）:
   Kingfisher  7.0+    → 网络图片加载缓存
   Lottie      4.4+    → 庆祝动画（可选）
```

> iOS 原生开发的最大优势之一：**几乎不需要第三方依赖**。Apple 原生框架覆盖了 95% 的需求。

---

## 九、Info.plist 权限配置

```xml
<key>NSCameraUsageDescription</key>
<string>FoodMoment 需要使用相机来拍摄食物照片进行营养分析</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>FoodMoment 需要访问您的相册以选择食物照片</string>

<key>NSHealthShareUsageDescription</key>
<string>FoodMoment 读取步数和体重数据以提供健康报告</string>

<key>NSHealthUpdateUsageDescription</key>
<string>FoodMoment 将营养摄入写入健康 App 以便统一管理</string>
```

---

## 十、里程碑总览

```
Week  1-2   ██░░░░░░░░░░░░░░░░░░  Xcode 项目 + SwiftUI 骨架 + Auth
Week  3-4   ████░░░░░░░░░░░░░░░░  📸 AVFoundation 相机 + Core ML 识别
Week  5-6   ██████░░░░░░░░░░░░░░  🔬 分析结果页 + Bottom Sheet
Week  7-8   ████████░░░░░░░░░░░░  📖 饮食日记 + SwiftData
Week  9-10  ██████████░░░░░░░░░░  🏠 首页仪表盘 + 三层环形图
Week 11-12  ████████████░░░░░░░░  📊 统计 + Swift Charts
Week 13-14  ██████████████░░░░░░  👤 个人中心 + HealthKit
Week 15-16  ████████████████░░░░  🚀 Widget + iOS 深度集成
Week 17-18  ██████████████████░░  🧪 测试 + 打磨 + 无障碍
Week 19-20  ████████████████████  🎉 TestFlight → App Store
```

---

## 十一、成本预估（月度）

| 项目 | 费用 |
|------|------|
| Apple Developer Program | ¥688/年 (≈ ¥57/月) |
| 云服务器 (2C4G) | ¥200/月 |
| 对象存储 (OSS) | ¥50/月 |
| AI API (Gemini / GPT-4o) | ¥500-2000/月 |
| USDA 食物数据库 | 免费 |
| CloudKit (iCloud 同步) | 免费 (1PB 资产 / 10GB 数据库) |
| Sentry 监控 | 免费 (Developer) |
| **合计（初期）** | **约 ¥800-2300/月** |

> 💡 iOS 原生 + CloudKit 的组合极大降低了基础设施成本。

---

## 十二、iOS 原生 vs Flutter 最终对比

| 维度 | iOS 原生 (SwiftUI) | Flutter |
|------|:------------------:|:-------:|
| 相机控制深度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 端侧 AI (Core ML + ANE) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 毛玻璃 Material | ⭐⭐⭐⭐⭐ 系统级 | ⭐⭐⭐⭐ 模拟 |
| 图表 (Swift Charts) | ⭐⭐⭐⭐⭐ 原生 | ⭐⭐⭐⭐ 三方 |
| HealthKit 集成 | ⭐⭐⭐⭐⭐ 直接 | ⭐⭐⭐ 桥接 |
| Widget / Live Activity | ⭐⭐⭐⭐⭐ | ⭐⭐ 需原生 |
| 包体积 | ~15MB | ~30-50MB |
| 第三方依赖数 | 2-3 个 | 15+ 个 |
| 跨平台 | ❌ iOS only | ✅ iOS + Android |
| App Store 审核 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

> **结论：** FoodMoment 重度依赖相机(AVFoundation)、端侧AI(Core ML)、健康数据(HealthKit)、精美动画(SwiftUI Animation) 和 iOS 生态(Widget/Live Activity)，**SwiftUI 原生是最优选择**。

---

> 📌 **下一步行动：** 确认后可立即开始 Sprint 1——创建 Xcode 项目、搭建 SwiftUI 骨架和设计系统。
