# Desktop（电脑端）Java Swing

Java Swing 桌面客户端现在默认使用本地 JSON 仓储，不需要启动 Node 后端。

## 功能
- 错题新增、编辑、删除
- 分类筛选和关键词搜索
- 随机复习，并记录掌握状态、复习次数、最近复习时间
- 顶部统计面板（总错题 + 分类计数 + 状态计数）

## 运行
```bat
run.bat
```

本地数据文件：

```text
%USERPROFILE%\.error-book\desktop-mistakes.json
```

如果数据文件不存在，首次启动会从仓库中的 `backend/mock-api/db.json` 导入一份初始数据。

## 测试
```bat
gradlew.bat test
```
