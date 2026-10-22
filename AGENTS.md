# Repository Guidelines

## Project Structure & Module Organization

This repository records practical Linux command-line labs. Run commands from the repository root.

- `scripts/` contains executable Bash utilities; `health.sh` generates a system health report.
- `notes/week01/` and `notes/week02/` contain weekly observations, commands, and explanations. Follow the `notes/weekNN/weekNN.md` pattern for new weeks.
- `evidence/` stores captured command output and generated reports supporting the notes. Quote paths containing spaces, such as `"evidence/test reports"`.
- `configs/`, `labs/`, and `src/` are currently empty placeholders. Add files there only when a lab needs them.

## Build, Test, and Development Commands

There is no build system or dependency installation step. The health script requires Bash and Linux utilities: `date`, `df`, `free`, `ps`, `ip`, and `ss`.

- `bash -n scripts/health.sh` checks Bash syntax without executing the script.
- `./scripts/health.sh "/tmp/field-lab reports"` runs the health check and prints the generated report path.
- `./scripts/health.sh` exercises argument validation; expect exit status `2`.

## Coding Style & Naming Conventions

Follow the existing script: use `#!/usr/bin/env bash`, `set -euo pipefail`, two-space indentation, and descriptive lowercase variables. Quote variable expansions and use `--` when passing paths to commands that support it. Keep executable permissions on scripts.

Handle expected failures explicitly. Capture `status=$?` immediately in an `else` branch; avoid capturing it after `!`, which inverts the original status. Preserve the report naming pattern `report-YYYYMMDD-HHMMSS-PID.txt`. No formatter or lint configuration is currently present.

## Testing Guidelines

Validation is manual; there is no automated test framework or coverage threshold. For script changes, check syntax, a successful run, a path containing spaces, invalid arguments, and an unwritable output destination. Check `echo $?` immediately after each run. Network inspection may fail in restricted environments; document that limitation and inspect any partial report. Record relevant output in `evidence/` and explain results in the corresponding weekly notes.

## Commit & Pull Request Guidelines

Existing commits use short, plain descriptions such as `Add lab 02 health report script, evidence, and notes`; no enforced prefix convention exists. Use concise action-oriented subjects identifying the lab and change. Pull requests should describe the purpose, affected files, validation commands, and observed exit statuses. Link an issue when applicable. Review evidence for sensitive host, network, and process details before committing.
