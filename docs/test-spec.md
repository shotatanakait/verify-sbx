# テスト仕様書

## 概要

本ドキュメントはnginx-lua-platformのテスト戦略・テストケース・合格基準を定義する。

## テスト戦略

```
┌─────────────────────────────────────┐
│  統合テスト (Test::Nginx)            │  ← 主要フロー・認証・エラー応答
├─────────────────────────────────────┤
│  ユニットテスト (busted)             │  ← ビジネスロジック・Redis操作・ルーティング
└─────────────────────────────────────┘
```

- ユニットテストは高速・独立を優先（Redisモック使用可）
- 統合テストは実際のHTTPリクエストで最終確認

## 合格基準

| 指標 | 基準値 |
|---|---|
| ユニットテスト カバレッジ（`app/services/`, `app/models/`） | 80% 以上 |
| 統合テスト 成功率 | 100% |
| `/health` レスポンスタイム | 10ms 以下 |
| レンダリング（キャッシュHIT時） | 5ms 以下 |

---

## ユニットテスト仕様

実行: `busted tests/unit/`

### UT-01: ルーター（`app/router.lua`）

| テストID | 入力 | 期待結果 |
|---|---|---|
| UT-01-01 | `GET /health` | ハンドラー `health.index` を返す |
| UT-01-02 | `POST /auth/token` | ハンドラー `auth.token` を返す |
| UT-01-03 | `GET /render/top` | ハンドラー `render.show` を返す |
| UT-01-04 | `GET /undefined-path` | `nil` と `404` を返す |
| UT-01-05 | メソッド不一致（`POST /health`） | `nil` と `405` を返す |

### UT-02: 認証ミドルウェア（`app/middleware/auth.lua`）

| テストID | 入力 | 期待結果 |
|---|---|---|
| UT-02-01 | 有効なBearerトークン | `client_id` が返る |
| UT-02-02 | Authorizationヘッダーなし | エラー `unauthorized` |
| UT-02-03 | 期限切れトークン | エラー `token_expired` |
| UT-02-04 | 署名が不正なトークン | エラー `invalid_token` |
| UT-02-05 | `Bearer` プレフィックスなし | エラー `unauthorized` |

### UT-03: レート制限（`app/middleware/rate_limit.lua`）

| テストID | 入力 | 期待結果 |
|---|---|---|
| UT-03-01 | 制限以下のリクエスト数 | `allowed = true` |
| UT-03-02 | 制限ちょうどのリクエスト数 | `allowed = true` |
| UT-03-03 | 制限超過 | `allowed = false`, `retry_after` が返る |
| UT-03-04 | 新しいウィンドウ（60秒後） | カウンターがリセットされ `allowed = true` |

### UT-04: Redisモデル（`app/models/`）

| テストID | 対象 | 入力 | 期待結果 |
|---|---|---|---|
| UT-04-01 | セッション保存 | `{client_id, token}` | Redis HSET 呼び出し、TTL 3600 |
| UT-04-02 | セッション取得 | 存在するトークン | セッションHashを返す |
| UT-04-03 | セッション取得 | 存在しないトークン | `nil` を返す |
| UT-04-04 | キャッシュ保存 | `{key, value, ttl}` | Redis SETEX 呼び出し |
| UT-04-05 | キャッシュ取得（HIT） | 存在するキー | キャッシュ値と `"HIT"` を返す |
| UT-04-06 | キャッシュ取得（MISS） | 存在しないキー | `nil` と `"MISS"` を返す |

### UT-05: コンテンツ生成サービス（`app/services/`）

| テストID | 入力 | 期待結果 |
|---|---|---|
| UT-05-01 | 存在するテンプレート名 | レンダリング済みHTML文字列を返す |
| UT-05-02 | 存在しないテンプレート名 | `nil` とエラーメッセージを返す |
| UT-05-03 | テンプレート変数を渡す | 変数が展開されたHTMLを返す |

---

## 統合テスト仕様

実行: `prove -r tests/integration/`

### IT-01: ヘルスチェック

**ファイル**: `tests/integration/health.t`

| テストID | リクエスト | 期待ステータス | 期待レスポンス |
|---|---|---|---|
| IT-01-01 | `GET /health` (Redis 正常) | 200 | `{"status":"ok","redis":"ok"}` |
| IT-01-02 | `GET /health` (Redis 停止) | 503 | `{"status":"degraded"}` を含む |

### IT-02: 認証フロー

**ファイル**: `tests/integration/auth.t`

| テストID | リクエスト | 期待ステータス | 確認内容 |
|---|---|---|---|
| IT-02-01 | `POST /auth/token` 正常 | 200 | `access_token`, `expires_in` フィールドを含む |
| IT-02-02 | `POST /auth/token` 認証情報不正 | 401 | `{"error":"invalid_credentials"}` |
| IT-02-03 | `POST /auth/token` ボディなし | 400 | `{"error":"bad_request"}` |

### IT-03: コンテンツレンダリング

**ファイル**: `tests/integration/render.t`

| テストID | リクエスト | 期待ステータス | 確認内容 |
|---|---|---|---|
| IT-03-01 | `GET /render/top` (有効トークン) | 200 | Content-Type: text/html |
| IT-03-02 | `GET /render/top` 2回目 | 200 | `X-Cache: HIT` ヘッダー |
| IT-03-03 | `GET /render/top?cache=false` | 200 | `X-Cache: MISS` ヘッダー |
| IT-03-04 | `GET /render/top` トークンなし | 401 | `{"error":"unauthorized"}` |
| IT-03-05 | `GET /render/nonexistent` | 404 | `{"error":"not found"}` |

### IT-04: レート制限

**ファイル**: `tests/integration/rate_limit.t`

| テストID | シナリオ | 期待ステータス | 確認内容 |
|---|---|---|---|
| IT-04-01 | 制限内のリクエスト | 200 | `X-RateLimit-Remaining` が減少する |
| IT-04-02 | 制限超過 | 429 | `Retry-After` ヘッダーを含む |

---

## テストデータ

### JWTシークレット（テスト用）

```
TEST_JWT_SECRET=test-secret-do-not-use-in-production
```

### テスト用クライアント認証情報

```
client_id=test-client
client_secret=test-secret
```

### テスト用Redisデータベース

`DB 1` を使用し、テスト終了後に `FLUSHDB` で初期化する。

---

## CI実行コマンド

```bash
# ユニットテスト
busted tests/unit/ --output=TAP

# 統合テスト（OpenResty起動済みの状態で）
TEST_NGINX_BINARY=openresty prove -r tests/integration/
```
