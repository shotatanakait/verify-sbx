#!/bin/bash
set -euo pipefail

# Claude Stop フック: タスク完了時に Chatwork へ通知

API_TOKEN="${CHATWORK_API_TOKEN:-}"
ROOM_ID="${CHATWORK_ROOM_ID:-}"
ACCOUNT_ID="${CHATWORK_ACCOUNT_ID:-}"
if [ -z "$API_TOKEN" ] || [ -z "$ROOM_ID" ]; then
  exit 0
fi

# stdin の JSON を読み捨て（フック仕様上必要）
cat > /dev/null

# SIP保護下のコマンドは相対パスで記載 (cf. gitは絶対パスで記載)
# Branch名はGit側で入力文字が制限されているためサニタイズなし
PROJECT_NAME=$(basename "$PWD")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null \
  || /opt/homebrew/bin/git rev-parse --abbrev-ref HEAD 2>/dev/null \
  || echo "不明")
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

curl -s -X POST "https://api.chatwork.com/v2/rooms/${ROOM_ID}/messages" \
  -H "X-ChatWorkToken: ${API_TOKEN}" \
  -d "body=${ACCOUNT_ID:+[To:${ACCOUNT_ID}]%0A}✅ Claude がタスクを完了しました%0Aプロジェクト: ${PROJECT_NAME}%0Aブランチ: ${BRANCH}%0A完了時刻: ${TIMESTAMP}" \
  > /dev/null

exit 0
