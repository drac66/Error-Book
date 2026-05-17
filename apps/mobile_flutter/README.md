# 学无止境

`学无止境` 是一个基于 Flutter 的离线错题本应用，面向日常学习场景，核心目标是帮助用户：

- 记录错题
- 管理错题本
- 基于复习计划进行回顾
- 自动累计学习打卡

项目当前以 Android 端离线使用为主，数据保存在本机，不依赖在线后端。

## 1. 项目特点

- 离线优先：错题、错题本、复习记录全部保存在本地 SQLite
- 图片录题：支持拍照或从相册选择图片
- OCR 识别：基于 ML Kit 进行本地文字识别
- 计划复习：按今日计划而不是随机抽题进行复习
- 自动打卡：完成当天计划后自动累计连续打卡
- 计划报告：支持以“学习报告/计划书”的方式查看今日复习任务

## 2. 当前主要功能

### 首页仪表盘

- 显示当前错题本
- 显示 `今日已学 / 今日应学 / 连续打卡`
- 展示最近复习时间
- 提供“开始复习”和“添加错题”快捷入口
- 显示最近更新的错题

### 错题本管理

- 查看错题本列表
- 搜索错题本
- 支持基于错题内容反向匹配错题本
- 默认包含“全部错题”视图
- 可新建错题本

### 错题录入与编辑

- 录入题干、错答、正答、解析
- 添加标签
- 选择所属错题本
- 设置掌握状态
- 设置题目难度
- 设置题目重要性
- 为题干、错答、正答添加图片
- 对图片执行 OCR 识别

### 复习计划

- 每个错题本独立生成当日计划
- 首页“开始复习”直接进入当前错题本的今日计划
- 支持“复习计划”报告页
- 显示计划总量、完成量、连续打卡、风险分布等

### 单题复习

- 先看题干，再翻看答案
- 支持记录三种状态：
  - 还不会
  - 继续复习
  - 已掌握
- 显示题目元信息：
  - 添加时间
  - 首次复习时间
  - 当前掌握状态
  - 累计复习次数
  - 连续掌握次数

### 打卡

- 当天计划全部完成后自动打卡
- 显示连续打卡天数
- 显示今日计划完成进度

### 设置

- 查看总错题、待复习、已掌握统计
- 导出本机调试 JSON
- 重建示例数据
- 查看版本信息

## 3. 复习计划逻辑

当前计划不是随机抽题，而是按优先级生成。

### 计划排序会参考这些因素

- 昨天复习但仍未掌握
- 距离上次复习的间隔时长
- 近期连续没做出来的次数
- 历史失败次数
- 当前掌握状态
- 连续掌握次数
- 题目难度
- 题目重要性

### 推题原则

- 新错题优先进入计划
- 昨天没掌握的题优先补救
- 久未复习的题优先回顾
- 难度高、重要性高的题优先级更高
- 已连续多次掌握的题会延长再次出现的间隔

这套策略不等同于严格的学术版艾宾浩斯算法，但产品意图与其一致：  
让不稳定的记忆更频繁出现，让稳定掌握的题延后回推。

## 4. 技术栈

### 客户端

- Flutter
- Dart

### 本地存储

- `sqflite`
- `shared_preferences`

### 图片与 OCR

- `image_picker`
- `google_mlkit_text_recognition`

### 其他依赖

- `path`
- `path_provider`
- `uuid`

## 5. 目录结构

```text
apps/mobile_flutter
├─ assets/                      资源文件
├─ lib/
│  ├─ app/                      应用入口与主题
│  ├─ config/                   应用常量配置
│  ├─ models/                   数据模型
│  ├─ pages/                    页面层
│  └─ services/                 本地数据与业务服务
├─ test/                        测试
├─ pubspec.yaml
└─ README.md
```

### 主要页面

- `mobile_home.dart`：移动端主入口
- `dashboard_page.dart`：首页仪表盘
- `review_page.dart`：错题本入口页
- `notebook_review_detail_page.dart`：错题本详情页
- `review_plan_report_page.dart`：复习计划报告页
- `review_plan_session_page.dart`：今日计划复习页
- `mistake_form_page.dart`：新增/编辑错题
- `mistake_review_page.dart`：单题复习页
- `review_checkin_page.dart`：打卡页
- `settings_page.dart`：设置页

### 主要服务

- `database_service.dart`：SQLite 初始化与升级
- `mistake_repository.dart`：错题与复习计划核心逻辑
- `notebook_repository.dart`：错题本管理
- `migration_service.dart`：初始化与示例数据迁移
- `image_storage_service.dart`：图片本地保存
- `image_text_service.dart`：图片选择与 OCR
- `app_services.dart`：服务聚合入口

## 6. 数据说明

### 错题模型核心字段

- `id`
- `notebookId`
- `question`
- `wrongAnswer`
- `correctAnswer`
- `reason`
- `category`
- `tags`
- `masteryStatus`
- `reviewCount`
- `difficultyLevel`
- `importanceLevel`
- `createdAt`
- `updatedAt`
- `lastReviewedAt`

### 掌握状态

- `new`：新错题
- `reviewing`：复习中
- `mastered`：已掌握

### 本地数据库表

- `notebooks`
- `mistakes`
- `review_events`

## 7. 运行方式

### 获取依赖

```bash
flutter pub get
```

### 本地运行

```bash
flutter run
```

### 静态检查

```bash
flutter analyze
```

### 运行测试

```bash
flutter test
```

## 8. 打包 APK

```bash
flutter build apk --release
```

输出位置：

```text
build/app/outputs/flutter-apk/app-release.apk
```

如果只是给同学体验，直接发 APK 即可。  
如果要给别人继续开发，建议发送当前 `apps/mobile_flutter` 目录源码，并去掉构建产物目录。

## 9. 适合的使用方式

这个项目比较适合：

- 自己整理学习错题
- 按错题本分科复习
- 通过“今日计划”来控制每天的复习量
- 通过难度、重要性和历史错误情况进行重点回顾

## 10. 当前限制

- 目前以本地离线为主，没有账号同步
- 主要针对移动端体验优化
- 桌面端与移动端功能尚未完全对齐
- OCR 识别质量受图片清晰度影响

## 11. 推荐后续演进方向

- 增加计划报告中的更多维度图表
- 增加错题导入/导出规范
- 支持跨设备同步
- 支持更细的复习参数调节
- 支持基于科目或标签的计划生成
