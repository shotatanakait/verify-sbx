# API仕様書

## 概要

本ドキュメントは nginx-lua-platform が提供するHTTP APIのエンドポイント仕様を定義する。

- ベースURL: `http://{host}:{port}`
- レスポンス形式: `application/json`（エラー時）または `text/html`（コンテンツ生成時）
- 認証: JWT Bearer Token（`Authorization: Bearer <token>`）

---

## 認証

### POST /auth/token

JWTトークンを発行する。

**リクエスト**

```
Content-Type: application/json
```

```json
{
  "client_id": "string",
  "client_secret": "string"
}
```

**レスポンス 200 OK**

```json
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

**レスポンス 401 Unauthorized**

```json
{ "error": "invalid_credentials" }
```

---

## コンテンツ生成

### GET /render/{template}

Luaテンプレートを動的レンダリングして返す。

**パスパラメーター**

| パラメーター | 型 | 必須 | 説明 |
|---|---|---|---|
| `template` | string | yes | テンプレート名（`views/` 配下のファイル名、`.html` 拡張子を除く） |

**クエリパラメーター**

| パラメーター | 型 | 必須 | 説明 |
|---|---|---|---|
| `cache` | boolean | no | `false` でキャッシュをバイパス（デフォルト: `true`） |

**リクエストヘッダー**

```
Authorization: Bearer <token>
```

**レスポンス 200 OK**

```
Content-Type: text/html; charset=utf-8
X-Cache: HIT | MISS
X-Render-Time: 1.23ms
```

レンダリング済みHTML本文

**レスポンス 404 Not Found**

```json
{ "error": "template not found" }
```

---

## ヘルスチェック

### GET /health

サーバーおよび依存サービスの稼働状態を返す。認証不要。

**レスポンス 200 OK**

```json
{
  "status": "ok",
  "redis": "ok",
  "uptime_seconds": 12345
}
```

**レスポンス 503 Service Unavailable**

```json
{
  "status": "degraded",
  "redis": "error: connection refused"
}
```

---

## 共通エラーレスポンス

| ステータスコード | エラーコード | 説明 |
|---|---|---|
| 400 | `bad_request` | リクエストパラメーターが不正 |
| 401 | `unauthorized` | トークン未提供または無効 |
| 403 | `forbidden` | 権限不足 |
| 404 | `not_found` | リソースが存在しない |
| 429 | `too_many_requests` | レート制限超過 |
| 500 | `internal_error` | サーバー内部エラー |

レート制限超過時は以下のヘッダーを付与する：

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1716800000
Retry-After: 60
```

---

## バージョニング方針

- URLパスにバージョンを含めない（現時点では単一バージョン）
- 破壊的変更が生じる場合は `/v2/` プレフィックスを追加して移行期間を設ける
