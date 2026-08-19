#!/bin/sh
# 把 assets/rules.md 装到指定位置。规则正文与工具无关,这里只负责各工具要的外包装。
#
# 用法:
#   install.sh              探测当前环境并装到检出的位置(等于 auto)
#   install.sh detect       只报告探测结果,不写任何文件
#   install.sh auto         探测并写入
#   install.sh <target>     指定位置
#   install.sh <target> --project   把 claude-md 从 ~ 改成当前目录
#
# target:
#   print         打印规则正文。粘到网页版对话框或任何"自定义指令"输入框
#   claude-style  ~/.claude/output-styles/speak-human.md(需再用 /output-style 选中)
#   claude-md     ~/.claude/CLAUDE.md,--project 时改 ./CLAUDE.md
#   agents-md     ./AGENTS.md
#   codex-global  ~/.codex/AGENTS.md
#   cursor        ./.cursor/rules/speak-human.mdc
#   copilot       ./.github/copilot-instructions.md
#   gemini        ./GEMINI.md
#
# Markdown 类目标用标记块包住,重复运行只替换块内内容。
# claude-style 和 cursor 是整文件覆盖,不要手改那两个文件,改 assets/rules.md 再重装。
set -eu

DIR=$(cd "$(dirname "$0")/.." && pwd)
RULES="$DIR/assets/rules.md"
BEGIN='<!-- speak-human:begin 由 speak-human skill 生成,块内内容会被覆盖 -->'
END='<!-- speak-human:end -->'
DESC='说人话:先结论后理由,判断必须指向可核对来源,推断标注出来,禁止比喻承担论证'

[ -f "$RULES" ] || { echo "找不到规则文件: $RULES" >&2; exit 1; }

usage() { sed -n '3,22p' "$0" >&2; }

upsert() {
  f="$1"
  mkdir -p "$(dirname "$f")"
  [ -f "$f" ] || : > "$f"
  tmp="$f.speak-human.tmp"
  awk -v b="$BEGIN" -v e="$END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip   { print }
  ' "$f" > "$tmp"
  # 去掉尾部空行,避免重复运行时空行累积
  if [ -s "$tmp" ]; then
    sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"
    printf '\n' >> "$tmp"
  fi
  printf '%s\n' "$BEGIN" >> "$tmp"
  cat "$RULES" >> "$tmp"
  printf '%s\n' "$END" >> "$tmp"
  mv "$tmp" "$f"
  echo "已写入 $f"
}

overwrite_with_frontmatter() {
  f="$1"; shift
  mkdir -p "$(dirname "$f")"
  { echo '---'; for line in "$@"; do echo "$line"; done; echo '---'; echo; cat "$RULES"; } > "$f"
  echo "已写入 $f"
}

install_target() {
  case "$1" in
    print) cat "$RULES" ;;
    claude-style)
      overwrite_with_frontmatter "$HOME/.claude/output-styles/speak-human.md" \
        'name: speak-human' "description: $DESC" 'keep-coding-instructions: true'
      echo '  ↳ 还没生效:运行 /output-style 选 speak-human,或在 settings.json 里设 "outputStyle": "speak-human"'
      ;;
    claude-md)
      if [ "${SCOPE:-}" = "--project" ]; then upsert "./CLAUDE.md"; else upsert "$HOME/.claude/CLAUDE.md"; fi ;;
    agents-md)    upsert "./AGENTS.md" ;;
    codex-global) upsert "$HOME/.codex/AGENTS.md" ;;
    gemini)       upsert "./GEMINI.md" ;;
    copilot)      upsert "./.github/copilot-instructions.md" ;;
    cursor)
      overwrite_with_frontmatter "./.cursor/rules/speak-human.mdc" \
        "description: $DESC" 'alwaysApply: true' ;;
    *) echo "未知目标: $1" >&2; usage; exit 1 ;;
  esac
}

# 探测。分三档:
#   运行时环境变量最可信,说明你此刻就在这个工具里 -> 装
#   项目里已有对应文件,说明这个项目已被那个工具读 -> 装
#   只有 home 目录痕迹,是全局配置,影响面大 -> 只报告,不装
detect() {
  HIT=''; NOTE=''
  in_claude=0
  if [ -n "${CLAUDECODE:-}${CLAUDE_CODE_ENTRYPOINT:-}" ]; then in_claude=1; HIT="$HIT claude-style"; fi
  if [ -n "${CURSOR_TRACE_ID:-}" ] || [ -d "./.cursor" ]; then HIT="$HIT cursor"; fi
  if [ -f "./AGENTS.md" ]; then HIT="$HIT agents-md"; fi
  if [ -f "./.github/copilot-instructions.md" ]; then HIT="$HIT copilot"; fi
  if [ -f "./GEMINI.md" ]; then HIT="$HIT gemini"; fi
  if [ -f "./CLAUDE.md" ] && [ "$in_claude" = 0 ]; then HIT="$HIT claude-md-project"; fi
  if [ -d "$HOME/.codex" ] && [ ! -f "./AGENTS.md" ]; then NOTE="$NOTE codex-global"; fi
  if [ -d "$HOME/.gemini" ] && [ ! -f "./GEMINI.md" ]; then NOTE="$NOTE gemini(需指定项目)"; fi
  if [ -d "$HOME/.claude" ] && [ "$in_claude" = 0 ]; then NOTE="$NOTE claude-style"; fi
  return 0
}

TARGET=${1:-auto}
SCOPE=${2:-}

case "$TARGET" in
  detect|auto)
    detect
    if [ -n "$HIT" ]; then
      echo "检出(会装):$HIT"
    else
      echo "没检出任何环境。用 print 把规则打出来自己粘,或显式指定 target。"
    fi
    if [ -n "$NOTE" ]; then echo "另外发现(不自动装,影响面大或需要你指定项目):$NOTE"; fi
    if [ "$TARGET" = "detect" ]; then exit 0; fi
    if [ -z "$HIT" ]; then echo; cat "$RULES"; exit 0; fi
    for t in $HIT; do
      echo
      if [ "$t" = "claude-md-project" ]; then SCOPE=--project; install_target claude-md; SCOPE=''
      else install_target "$t"; fi
    done
    ;;
  *) install_target "$TARGET" ;;
esac
