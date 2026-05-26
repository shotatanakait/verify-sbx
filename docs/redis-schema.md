# Redis データ設計書

## 概要

本ドキュメントは nginx-lua-platform が使用するすべてのRedisキーの命名規則、データ構造、TTLポリシーを定義する。

- Redis バージョン: 7.x 以上推奨
- データベース番号: `DB 0`（本番）/ `DB 1`（テスト）
- キーの文字コード: UTF-8

---

## キー命名規則

```
{namespace}:{entity}:{identifier}[:{subkey}]
```

| セグメント | 説明 | 例 |
|---|---|---|
| namespace | アプリケーション名プレフィックス | `nlp` |
| entity | データ種別 | `session`, `cache`, `ratelimit` |
| identifier | 一意識別子 | ユーザーID、IPアドレス等 |
| subkey | 任意の追加分類 | `page`, `block` |

---

## キー定義

### セッション

| キー | 型 | TTL | 説明 |
|---|---|---|---|
| `nlp:session:{token}` | Hash | 3600秒 | JWTトークンに紐づくセッションデータ |

**Hash フィールド**

| フィールド | 型 | 説明 |
|---|---|---|
| `client_id` | string | クライアント識別子 |
| `created_at` | integer | Unixタイムスタンプ（秒） |
| `last_seen` | integer | 最終アクセス時刻（Unixタイムスタンプ） |

**操作例**

```lua
red:hset("nlp:session:" .. token, "client_id", client_id,
                                   "created_at", os.time())
red:expire("nlp:session:" .. token, 3600)
```

---

### レンダリングキャッシュ

| キー | 型 | TTL | 説明 |
|---|---|---|---|
| `nlp:cache:render:{template}:{params_hash}` | String | 300秒 | テンプレートレンダリング結果 |

- `params_hash`: クエリパラメーターをソート済みJSON文字列にしたMD5ハッシュ（8文字）
- キャッシュは `Content-Type` ヘッダー値をプレフィックスに付けて格納する

**操作例**

```lua
local key = "nlp:cache:render:" .. template .. ":" .. params_hash
red:setex(key, 300, rendered_html)
```

---

### レート制限

| キー | 型 | TTL | 説明 |
|---|---|---|---|
| `nlp:ratelimit:{client_id}:{window}` | String | 60秒 | 1分間のリクエスト数カウンター |

- `window`: `math.floor(ngx.time() / 60)` で算出した分単位のウィンドウ番号
- 値は INCR で加算し、初回設定時のみ EXPIRE を付与する（sliding windowではなく fixed window）

**操作例**

```lua
local key = "nlp:ratelimit:" .. client_id .. ":" .. math.floor(ngx.time() / 60)
local count = red:incr(key)
if count == 1 then
    red:expire(key, 60)
end
```

---

### 共有設定

| キー | 型 | TTL | 説明 |
|---|---|---|---|
| `nlp:config:{key}` | String | なし（永続） | 動的設定値（起動後に変更可能なパラメーター） |

**キー一覧**

| キー名 | デフォルト | 説明 |
|---|---|---|
| `nlp:config:ratelimit_max` | `100` | 1分間の最大リクエスト数 |
| `nlp:config:cache_ttl` | `300` | レンダリングキャッシュTTL（秒） |
| `nlp:config:maintenance` | `0` | `1` でメンテナンスモード |

---

## 運用ポリシー

### メモリ上限

```
maxmemory 256mb
maxmemory-policy allkeys-lru
```

- セッションおよびキャッシュキーは LRU で自動削除可能
- `nlp:config:*` は永続キーのため LRU 削除対象にならない（`volatile-lru` ではなく `allkeys-lru` を使うこと）

### キーの削除

- セッション破棄: `DEL nlp:session:{token}`
- キャッシュパージ（特定テンプレート）: `SCAN` + パターン `nlp:cache:render:{template}:*` でキーを収集して `DEL`
- 全キャッシュクリア: `SCAN` + パターン `nlp:cache:*`（本番環境では `FLUSHDB` を使わない）

### モニタリング

以下のコマンドで定期的にキー数とメモリを確認する：

```bash
redis-cli INFO keyspace
redis-cli INFO memory
redis-cli --scan --pattern 'nlp:*' | wc -l
```
