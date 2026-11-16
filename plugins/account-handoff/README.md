# account-handoff: a Claude Code plugin for claude-multi-desktop

One skill, `handoff`, for people who run several Claude Desktop accounts on one Mac with
[claude-multi-desktop](https://github.com/jackson-cmd/claude-multi-desktop). It hands a task, a question or a
summary to a Claude Code session running in another account and relays the reply, using Claude Code's
`ListAgents` and `SendMessage` tools and `claude-multi-desktop peers` to tell which session runs in which account.

```text
/plugin marketplace add jackson-cmd/claude-multi-desktop
/plugin install account-handoff@multi-desktop
```

Then ask in plain words, for example *"ask the build fix session in my Work account to run the tests and tell me
what fails"*, or type `/account-handoff:handoff Work run the tests`.

The skill refuses to move work to another account because one account has reached a usage or rate limit; the tool
is meant for keeping separate accounts open side by side, not for getting around limits.

Unofficial; not affiliated with Anthropic. MIT License.
