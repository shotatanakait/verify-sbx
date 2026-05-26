**[STOP] 前提チェック（最優先・必須）**

Issue番号: `$ARGUMENTS`
上記が空（`` の状態）の場合は、`Usage: /start-issue <issue-number>` とのみ出力し、

**以降の手順を一切実行せずに終了すること。**

---

Issue#$ARGUMENTS を Git Worktree を使用して実装して下さい。

## 実装手順

### 1. 前処理(Worktree作成前)

- デフォルトブランチ(`main` or `master` or `develop`)にチェックアウトして下さい。
- 最新のデフォルトブランチを取得して下さい。(`git pull origin <default-branch>`)
- 既存Worktreeがあれば削除して下さい。(`git worktree remove --force ../issue-$ARGUMENTS 2>/dev/null || true`)
- 既存ブランチがあれば削除して下さい。(`git branch -D feature/issue-$ARGUMENTS 2>/dev/null || true`)

### 2. Worktree作成

- Worktreeを作成して下さい。(`git worktree add ../issue-$ARGUMENTS -b feature/issue-$ARGUMENTS`)
- Worktreeのサブディレクトリは、`issue-$ARGUMENTS`という命名規則に従った形式とします。

### 3. Worktreeの環境設定

- 作成したサブディレクトリに移動して下さい。(`cd ../issue-$ARGUMENTS`)
- プロジェクトの依存関係をインストールして下さい。(Node.jsプロジェクトでpackage.jsonがあれば、npm/yarn/pnpm等)

### 4. 実装

- Issue内容を取得して確認して下さい。(`gh issue view $ARGUMENTS`)
- このIssueを実装するのに最適なサブエージェントを選択して、実装して下さい。

### 5. PR作成

- 問題なければ変更をコミットして、リモートにプッシュして下さい。
- PRを作成して下さい。
- PRタイトルは、「<type>(feat/fix/chore等): Issue#$ARGUMENTS [Issueの内容を要約]」の形式とします。
- PRのターゲットブランチは、デフォルトブランチ(`main` or `master` or `develop`)に設定して下さい。
