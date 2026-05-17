# Review Plan Upgrade Requirements

## Problem

当前移动端已经有基础复习和自动打卡能力，但用户看到的仍然更像“随机抽题 + 错题列表”，而不是“每日学习计划”。这会削弱复习节奏感，也无法把高风险题和已经稳定掌握的题区分开。

本次改造目标是把复习体验升级为“计划驱动”的学习流程，参考百词斩的任务心智：

- 首页显示今日计划进度
- 首页开始复习直接进入当前错题册的今日计划
- 复习计划入口进入一页报告式的数据界面
- 完成今日计划后自动打卡
- 推题逻辑优先照顾昨日未掌握、长期未复习、多次做错的题，并对连续多次掌握的题延后推送

## Scope

In scope:

- Flutter 移动端首页、复习详情、打卡页、单题复习页升级
- 每日复习计划生成逻辑升级
- 每日计划缓存按错题册隔离
- 新增计划报告页和计划会话页
- 自动打卡与计划完成联动

Out of scope:

- 服务端同步
- 账号体系
- 多设备计划合并

## User Stories

1. 作为学生，我希望首页直接看到今天已复习多少题、还剩多少题，这样我能知道今天的学习进度。
2. 作为学生，我希望点击“开始复习”后进入当前错题册的今日计划，而不是随机抽题。
3. 作为学生，我希望“复习计划”是一个报告/计划页，而不是错题列表，这样我能先判断今天任务结构，再决定开始。
4. 作为学生，我希望昨天复习仍未掌握的题今天继续出现，且多次做错、久未复习的题优先出现。
5. 作为学生，我希望已经连续多次掌握的题不要每天都来，而是按更长间隔回推。
6. 作为学生，我希望完成今天计划后自动打卡，并能看到连续打卡天数。
7. 作为学生，我希望在单题复习页看到添加时间、首次复习时间和当前掌握状态。

## Acceptance Criteria

1. When the user opens the home dashboard, the system shall display today's reviewed count and today's planned count for the current study notebook.
2. When the user taps the home “开始复习” action, the system shall open a review session containing the remaining planned mistakes for the current study notebook.
3. When the user taps the notebook “复习计划” action, the system shall open a report-style review plan screen instead of a mistake list.
4. When a mistake was reviewed yesterday and is still not mastered, the review planner shall prioritize it for today's plan.
5. When a mistake has not been reviewed for a long time and has multiple failed reviews, the review planner shall raise its priority in today's plan.
6. When a mistake has been mastered repeatedly, the review planner shall delay its next appearance using a longer review interval.
7. When the user finishes all items in today's plan for the active plan scope, the system shall automatically mark the day as checked in.
8. When the user opens the check-in screen, the system shall display whether today's check-in is complete and the current streak.
9. When the user opens a single mistake review screen, the system shall display the mistake created time, first reviewed time, and current mastery status.

## Assumptions

- “当前选中的错题册”使用最近一次进入/学习的错题册；如果没有，则默认使用“全部错题”范围。
- 每日计划按错题册独立缓存；自动打卡以当前完成的计划范围为依据。
- 单次计划完成后可继续查看报告页或打卡页，不要求强制退出。
