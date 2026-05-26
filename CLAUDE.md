# nginx-lua-platform

OpenResty（nginx + LuaJIT）を基盤とした高速WEBアプリケーションプラットフォーム。
Lua スクリプトで動的コンテンツを生成し、Redis をキャッシュ・セッション層として活用する。

## 関連ドキュメント

| ドキュメント | 内容 |
|---|---|
| [docs/api-spec.md](docs/api-spec.md) | エンドポイント定義・リクエスト/レスポンス仕様 |
| [docs/redis-schema.md](docs/redis-schema.md) | Redisキー設計・データ構造・TTLポリシー |
| [docs/test-spec.md](docs/test-spec.md) | テストケース・合格基準・CIコマンド |

## Technology Stack

| コンポーネント | 用途 |
|---|---|
| OpenResty (nginx + LuaJIT) | HTTPサーバー・Luaランタイム |
| lua-resty-redis | Redis クライアント（非同期cosocket） |
| lua-resty-template | HTMLテンプレートエンジン |
| lua-resty-jwt | JWT認証 |
| Redis | キャッシュ・セッション・レート制限 |

## Project Structure

```
verify-sbx/
├── CLAUDE.md
├── nginx/
│   ├── nginx.conf            # メイン設定（worker数、イベントモデル）
│   ├── conf.d/
│   │   ├── app.conf          # バーチャルホスト設定
│   │   └── upstream.conf     # アップストリーム定義
│   └── lua_packages/         # サードパーティLuaライブラリ
├── app/
│   ├── init.lua              # 起動時初期化（lua_package_path等）
│   ├── router.lua            # URLルーティング
│   ├── middleware/
│   │   ├── auth.lua          # JWT認証ミドルウェア
│   │   └── rate_limit.lua    # レート制限
│   ├── handlers/             # リクエストハンドラー（1ファイル1ルート）
│   ├── services/             # ビジネスロジック
│   ├── models/               # Redisアクセス層
│   └── views/                # luaテンプレート (.html)
├── scripts/
│   ├── start.sh
│   ├── stop.sh
│   └── reload.sh
├── tests/
│   ├── unit/                 # busted によるユニットテスト
│   └── integration/          # Test::Nginx による統合テスト
└── logs/
    ├── access.log
    └── error.log
```

## Setup & Installation

### OpenResty のインストール

```bash
# Ubuntu/Debian
sudo apt-get install -y openresty

# 実行確認
openresty -v
```

### Redis のインストール

```bash
sudo apt-get install -y redis-server
sudo systemctl start redis-server
redis-cli ping  # PONG が返ればOK
```

### テストツールのインストール

```bash
# busted（Lua ユニットテストフレームワーク）
sudo luarocks install busted

# cpanm + Test::Nginx（統合テスト）
sudo cpanm --notest Test::Nginx
```

## Development Workflow

### サーバー操作

```bash
./scripts/start.sh    # 起動
./scripts/stop.sh     # 停止
./scripts/reload.sh   # 設定リロード（無停止）

# 直接操作
openresty -p $(pwd) -c nginx/nginx.conf        # 起動
openresty -p $(pwd) -c nginx/nginx.conf -s reload  # リロード
openresty -p $(pwd) -c nginx/nginx.conf -s stop    # 停止

# 設定テスト（起動前に必ず実行）
openresty -p $(pwd) -c nginx/nginx.conf -t
```

### 開発中のデバッグ

```bash
# エラーログをリアルタイム確認
tail -f logs/error.log

# Lua コードからのデバッグ出力（error.log に記録される）
ngx.log(ngx.ERR, "debug: ", require("cjson").encode(data))

# nginx デバッグビルドが必要な場合
openresty -V 2>&1 | grep debug
```

## Coding Standards

### Lua スタイル

- インデント: スペース2つ
- 変数名: `snake_case`
- モジュール名: `PascalCase`
- 定数: `UPPER_SNAKE_CASE`
- ローカル変数を積極的に使う（グローバル汚染を避ける）
- モジュールトップで `local` 変数にキャッシュ: `local ngx = ngx`

### OpenResty フェーズの使い分け

| フェーズ | ディレクティブ | 用途 |
|---|---|---|
| init | `init_by_lua_block` | 設定読み込み、共有変数初期化 |
| rewrite | `rewrite_by_lua_block` | URLリライト、早期リダイレクト |
| access | `access_by_lua_block` | 認証・認可・レート制限 |
| content | `content_by_lua_block` | レスポンス生成（メイン処理） |
| header_filter | `header_filter_by_lua_block` | レスポンスヘッダー操作 |
| log | `log_by_lua_block` | アクセスログ・メトリクス収集 |

### Redis アクセスパターン

```lua
-- models/ 内で統一されたパターンを使う
local redis = require "resty.redis"

local function get_client()
    local red = redis:new()
    red:set_timeout(1000)  -- 1秒
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        return nil, "failed to connect: " .. err
    end
    return red
end

local function release(red)
    -- コネクションプールに返却（keepalive）
    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        red:close()
    end
end
```

### エラーハンドリング

```lua
-- ngx.exit() で早期終了、エラーは JSON で返す
local function json_error(status, message)
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    ngx.say(require("cjson").encode({ error = message }))
    ngx.exit(status)
end
```

### 禁止事項

- ブロッキングI/O（`io.open`, `os.execute` 等）を content/access フェーズで使わない
- グローバル変数への書き込み（workerをまたいで共有されない）
- `require()` をリクエストごとに呼ばない（モジュールレベルでキャッシュする）

## Testing Approach

### ユニットテスト（busted）

```bash
# 全テスト実行
busted tests/unit/

# 特定ファイル
busted tests/unit/router_spec.lua
```

`tests/unit/` 配下に `*_spec.lua` の命名規則でテストファイルを作成する。

### 統合テスト（Test::Nginx）

```bash
# prove でテスト実行
prove -r tests/integration/
```

`tests/integration/` 配下に `*.t` ファイルを配置する。
実際のHTTPリクエスト・レスポンスを検証する。

### テスト方針

- ハンドラーのビジネスロジックは services/ に分離し、ユニットテスト可能にする
- Redis依存のコードはモック（または本物のRedisインスタンス）を使う
- 統合テストは主要なルートと認証フローをカバーする

## Performance Guidelines

- `lua_shared_dict` で worker 間の共有キャッシュを使う（Redisアクセス削減）
- レスポンスキャッシュは `ngx.ctx` ではなく shared_dict または Redis に保存
- `ngx.timer.at` で非同期バックグラウンド処理を実装する
- `ngx.location.capture` よりも直接 Lua でロジックを書く方が高速

## Environment Variables

nginx.conf 内では `$ENV{VAR_NAME}` でOS環境変数を参照できる（`env` ディレクティブ要設定）。

```nginx
env REDIS_HOST;
env REDIS_PORT;
```

Lua からは `os.getenv("REDIS_HOST")` で取得する（`init_by_lua_block` 内で読み込んで共有変数に格納する）。
