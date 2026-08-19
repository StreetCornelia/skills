#!/usr/bin/env bash
# 每 N 轮对话向上下文注入一次"更新脑图"提醒。
# 供 Claude Code 的 UserPromptSubmit hook 调用,stdout 会作为上下文送给模型。
# 用法:turn-counter.sh [阈值]   默认 15 轮
# 任何异常都静默退出 0,避免阻塞用户的提问。

set -u

THRESHOLD="${1:-15}"
DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.claude"
STATE="$DIR/.dialog-map-turns"

mkdir -p "$DIR" 2>/dev/null || exit 0

COUNT=0
[ -f "$STATE" ] && COUNT=$(tr -dc '0-9' < "$STATE" 2>/dev/null | head -c 6)
[ -z "$COUNT" ] && COUNT=0
COUNT=$((COUNT + 1))

if [ "$COUNT" -ge "$THRESHOLD" ]; then
  echo 0 > "$STATE" 2>/dev/null
  echo "[dialog-map] 已过 $THRESHOLD 轮对话。若这段讨论产生了决策、否决的方案或新发现的约束,现在用 dialog-map skill 更新 .claude/dialog-map.md;若只是执行性往返,跳过即可,不必为了记录而记录。"
else
  echo "$COUNT" > "$STATE" 2>/dev/null
fi

exit 0
