---
name: speak-human
description: 说人话:按一套工具无关的规则重写刚才那段回复——先结论后理由,每个判断句要能指向可核对的来源,推断标注出来,比喻不许承担论证,同时禁止滑向公文体的名词化和被动语态。用户提到说人话、重说一遍、别整修辞、去掉文学腔、说具体点、别下空判断、工程语言、/speak-human 时使用;用户说要安装、装到我的环境里、以后都这么说时,跑 scripts/install.sh 自动探测环境后写入。只在用户明确要求时使用,不主动套用。
---

# 说人话(speak human)

## 默认动作:重写刚才那段

被调用就意味着**上一条回复没通过,要重写**,不是从下一条起注意一点。

1. 取自己最近发出的那条回复(用户另外指定了范围就按用户说的)。
2. 读 [assets/rules.md](assets/rules.md),逐条改写,输出改写后的完整内容。不要输出"我改了哪几处"这种差异说明——用户要的是能直接用的那一版。
3. 自检第 1 条(承担论证的那句话,换成具体数字或具体场景后还成不成立)是唯一会真正改写内容的一条。如果某句改写后发现论证不成立,不要保留它换个说法,直接删掉或标为推测。
4. 末尾可以用一两行说明删掉了什么、哪些判断降级成了推测。这是唯一允许的元信息,其他一律不加。
5. 之后的回复继续按这套规则输出,直到用户说停。

改写时最容易走的偏路是只换词:把"咬出"换成"逼出",把"税"换成"成本代价"。这样过不了自检——同义替换不改变论证是不是空的。

## 用户说要安装时

```
scripts/install.sh
```

无参数就是探测当前环境并写入。`scripts/install.sh detect` 只报告不写。

探测分三档:

- **运行时环境变量命中**(`CLAUDECODE`、`CURSOR_TRACE_ID`)→ 装。这说明用户此刻就在这个工具里。
- **项目里已有对应文件**(`./AGENTS.md`、`./.cursor/`、`./.github/copilot-instructions.md`、`./GEMINI.md`、`./CLAUDE.md`)→ 装。这说明这个项目已经被那个工具读。
- **只有 home 目录痕迹**(`~/.codex`、`~/.gemini`、`~/.claude` 但不在 Claude Code 里)→ 只报告,不装。这些是全局配置,影响面大,让用户自己决定。

什么都没检出时,打印规则正文让用户自己粘。

也可以指定位置:`print`、`claude-style`、`claude-md`(加 `--project` 改写 `./CLAUDE.md`)、`agents-md`、`codex-global`、`cursor`、`copilot`、`gemini`。

装完不要顺手改 `settings.json` 之类的开关配置。`claude-style` 写完还要用户自己用 `/output-style` 选中,脚本会把这句打出来。

## 规则正文为什么这么写

[assets/rules.md](assets/rules.md) 是唯一一份正文,44 行。它不是禁词表。禁词表同义替换就能绕过,所以正文里另外有三样东西:

- **正面规格**:每个判断句要能指向命令输出、某文件某行、或对方原话。这条没法用换词满足。
- **结构约束**:段末总结升华句、三项并列排比、"总之/综上"收尾段。这些用的全是普通词汇,禁词表一条也拦不住。
- **反向约束**:只封文学一侧,输出会滑向公文体("进行优化""实现了对 X 的支持")。所以同时禁止名词化和被动语态当默认。

加新规则前先问:它能被同义替换绕过吗?能就改写成正面规格(要求输出里出现什么可核对的东西),而不是再加一个禁词。

## 各安装位置的核对情况

- `claude-style` 的三个 frontmatter 字段(`name`、`description`、`keep-coding-instructions`)是从 Claude Code 2.1.212 二进制里的加载逻辑读出来的:`name` 缺省取文件名,`description` 缺省取正文首段。`keep-coding-instructions: true` 是为了保留原本的编码指令、只叠加文体约束,这个字段的语义我按字段名和它在解析函数里的位置推断,没实测开关前后的差异。官方文档:`https://code.claude.com/docs/en/output-styles.md`。
- `CLAUDECODE` 环境变量在本机确认存在(Claude Code 2.1.212)。`CURSOR_TRACE_ID` 我没有 Cursor 可测,是按公开约定写的。
- `cursor`、`copilot`、`codex-global`、`gemini` 的文件位置和 frontmatter 没在本机验证,装完请确认工具是否真的读到了。
- `print`、`agents-md`、`claude-md` 是普通 Markdown,没有格式风险。
- 标记块的重复写入实测过:在一个已有内容的 AGENTS.md 上连跑三次,行数稳定、标记块数为 1、原有内容都在。`claude-style` 和 `cursor` 是整文件覆盖,不要手改这两个文件,改 `assets/rules.md` 再重装。
