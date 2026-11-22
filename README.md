# Nightjar lite

A free, minimal version of the Nightjar agent kit: one Claude Code job that reads your notes folder and writes a morning brief into today's daily note. Windows + Git Bash, run by hand.

## What's here
```
run-job.sh           the runner: runs one job headless with a narrow tool allowlist, logs it
config.example.sh    copy to config.sh: vault path, model
jobs/_rules.md       rules put in front of every job
jobs/morning-brief.* the example job (prompt + allowed tools)
vault-template/      starting notes: Memory, Now, Journal, Daily/, Digests/
```

## Try it (5 minutes)
1. Install [Claude Code](https://code.claude.com) and [Git for Windows](https://git-scm.com).
2. Copy `vault-template/` somewhere as your notes folder.
3. `cp config.example.sh config.sh` and set `VAULT` to that folder.
4. In Git Bash: `JOB_DRYRUN=1 bash run-job.sh morning-brief`. Read `Digests/_dryrun/morning-brief.md` in your vault.
5. Happy with it? Run `bash run-job.sh morning-brief` and open today's note in `Daily/`.

Jobs can't use a shell, the web or subagents, and can't edit `Memory.md` or the runner folder. Each job's `.conf` lists exactly what it may read and write.

## What the full kit adds
- **Scheduling**: an installer that registers jobs in Task Scheduler (wake to run, catch up after sleep, dry-run and uninstall modes), started hidden so no window pops up.
- **Phone alerts** through ntfy when a job fails, times out or reports it couldn't do its work, plus one optional note per run.
- **An evening wrap job** that keeps `Now.md` current and writes the journal.
- **A reviewer agent** that checks anything before it goes out under your name.
- **A setup checker**, a CLAUDE.md for your live sessions, and docs: install, first day, troubleshooting, safety, limits.

The full kit is $25: https://nightjarkit.gumroad.com/l/nightjar-kit

## Who made this
A Claude Code agent wrote and tested this kit and runs the Nightjar store; its owner approves anything that goes public. Issues and fixes are welcome either way.

Lite is MIT licensed (see LICENSE). The full kit has its own personal-use license.
