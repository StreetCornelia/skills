# 接近"自动触发"的几种接法

前提要说清楚:**skill 本身不能自己醒来**,它只是一份被模型读取的指令文档,没有定时器,也无法监听对话轮数。能主动发起动作的只有 Claude Code 的 hooks。hooks 能做的也不是"替你更新脑图",而是**把提醒注入上下文**,由模型读到后再执行本 skill。理解这一点,下面三种接法的定位就清楚了。

配置写在 `~/.claude/settings.json`(全局)或项目内 `.claude/settings.json`(仅该项目)。改完需要重启会话生效。

## 接法一:每 N 轮提醒(最接近你要的效果)

用 `UserPromptSubmit` hook —— 它在你每次提问时运行,标准输出会作为上下文送给模型。配合本 skill 的计数脚本,每 15 轮提醒一次:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/skills/dialog-map/scripts/turn-counter.sh 15"
          }
        ]
      }
    ]
  }
}
```

计数状态存在 `.claude/.dialog-map-turns`,按项目独立。阈值改末尾数字即可:讨论密集的项目用 10,执行型任务多的用 20~30。脚本任何异常都静默退出,不会挡住你提问。

注意这是**提醒**不是强制:模型读到提醒后会自行判断这段对话有没有值得记的内容,没有就跳过。这是有意的——强制每 15 轮必须写点什么,文件很快会被灌成流水账,那时它就失去价值了。

## 接法二:压缩前落盘(最该配的一个)

`PreCompact` 在上下文压缩前触发,正是判断最容易丢失的时刻。压缩摘要是尽力而为的,`dialog-map.md` 是确定的:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[dialog-map] 即将压缩上下文。先用 dialog-map skill 把本段对话中的决策、否决方案和待决问题写入 .claude/dialog-map.md,再继续压缩。'"
          }
        ]
      }
    ]
  }
}
```

`matcher` 取 `auto`(上下文满时自动压缩)或 `manual`(你手敲 `/compact`),想两种都覆盖就写两个条目。

各版本 Claude Code 对 PreCompact 输出的处理时机略有差异,配完后建议实测一次:让对话接近压缩、观察提醒有没有出现。如果这个 hook 在你的版本上不生效,退回到手动——在敲 `/compact` 前先说一句"更新脑图",效果完全一样。

## 接法三:开新会话时先读

`SessionStart` 的输出会进入新会话的上下文,用来解决"新会话重复踩坑"的问题:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "test -f .claude/dialog-map.md && echo '[dialog-map] 本项目有对话脑图 .claude/dialog-map.md,涉及既有议题时先读它,避免重提已否决的方案。'"
          }
        ]
      }
    ]
  }
}
```

## 建议的组合

只配一个就配**接法二**,它覆盖了最高价值的时刻。三个都配起来,才形成完整闭环:定期提醒(一)→ 压缩前落盘(二)→ 新会话读回(三)。

不想碰配置文件也完全可用:在感觉"这段讨论有价值"或"上下文快满了"的时候说一句"更新脑图"。手动触发的判断质量通常比定时触发更高,因为你知道刚才那段到底有没有料。
