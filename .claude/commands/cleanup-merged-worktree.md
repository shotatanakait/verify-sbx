**[STOP] 前提チェック（最優先・必須）**

Issue番号: `$ARGUMENTS`
上記が空（`` の状態）の場合は、`Usage: /cleanup-merged-worktree <issue-number>` とのみ出力し、

**以降の手順を一切実行せずに終了すること。**

---

Issue#$ARGUMENTS のマージ済みWorktreeをクリーンアップして下さい。

## 手順

### 1. PRのマージ確認

- PRがマージ済みか確認して下さい。(`gh pr list --head feature/issue-$ARGUMENTS --state merged`)
- マージされていない場合は処理を中断して下さい。

### 2. Worktree削除

- Worktreeを削除して下さい。(`git worktree remove --force ../issue-$ARGUMENTS 2>/dev/null || true`)
- ローカルブランチを削除して下さい。(`git branch -D feature/issue-$ARGUMENTS 2>/dev/null || true`)
- 不要なWorktree参照を整理して下さい。(`git worktree prune`)
