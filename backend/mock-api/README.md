# Mock API

Node.js 原生 HTTP 服务，使用 `db.json` 保存错题数据。

## 运行
```bash
npm start
```

默认地址：`http://127.0.0.1:8787`

## 测试
```bash
npm test
```

## 接口
- `GET /health`
- `GET /mistakes?keyword=&category=`
- `GET /mistakes/random`
- `POST /mistakes`
- `PUT /mistakes/:id`
- `DELETE /mistakes/:id`
- `GET /stats`
