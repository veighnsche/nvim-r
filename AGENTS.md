# AGENTS.md

This repo is a shared Neovim config. It is used across multiple Linux
distributions and is expected to behave consistently.

## Non-Negotiable Rule

Bootstrap failures must be fixed at bootstrap.

Do not hide them in runtime Lua.

The visible error is a useful signal. If bootstrap is missing, that signal
should stay visible until bootstrap is repaired.

If a host is missing a required binary, parser, CLI, compiler, or package:

- identify the missing prerequisite
- fix installation/bootstrap
- keep runtime behavior the same

If bootstrap is incomplete, a loud and clear failure is preferred over silent
degradation.

## Priority Order

When making changes in this repo, optimize in this order:

1. Correctness
2. Reproducibility
3. Observability
4. Consistency across hosts
5. Convenience

Do not trade away the first four just to make startup quieter.

## Error Signals Are Desired

In this repo, a startup error caused by a missing dependency is usually a good
thing. It tells the next engineer exactly what is missing.

Do not "improve" the experience by removing that signal while leaving the host
in a broken state.

If the dependency is required, the correct behavior is:

- fail clearly
- fix bootstrap
- re-test

## Forbidden Behavior

The following are explicitly wrong in this repo unless the user asks for them:

- disabling features at runtime because a dependency is missing
- silently swapping to a different implementation on one distro
- suppressing errors that indicate missing bootstrap
- turning infrastructure problems into conditional editor behavior
- making Alpine, Fedora, or any other host "work differently" by default
- papering over a broken dependency instead of installing the correct one
- making a startup problem disappear without repairing the host

## Failure Masking

Failure masking means making the symptom disappear while the environment remains
wrong.

Examples:

- disabling `render-markdown.nvim` because markdown parsers are missing
- skipping markdown LSP because the installed binary is incompatible
- silently refusing tree-sitter parser setup because `tree-sitter` is missing
- adding distro-specific runtime branches to avoid obvious startup errors

Failure masking is a bad fix here because it:

- hides the real problem
- destroys reproducibility
- creates cross-host drift
- weakens useful error signals
- makes the config dishonest
- teaches the wrong fix to the next engineer

## Expected Markdown Policy

Markdown must use one intentional stack across hosts.

That means:

- one markdown LSP choice
- one markdown rendering path
- one parser strategy

If a distro needs different install commands to reach that same stack, put the
difference in bootstrap scripts or docs, not in runtime plugin logic.

Do not "fall back" to a different markdown server or different markdown
behavior just to make one machine limp along.

## Bootstrap-First Workflow

When something fails on one host:

1. Reproduce the failure.
2. Name the exact missing prerequisite.
3. Decide where bootstrap should install it from.
4. Add or fix bootstrap instructions or scripts.
5. Keep the runtime config uniform.
6. Verify the same file behaves the same way on each distro.

## What To Do Instead Of Masking

Good fixes:

- install the correct binary
- install the correct parser toolchain
- install the correct system package
- fetch the correct release artifact for the host
- document or script distro-specific bootstrap commands
- let startup fail clearly until bootstrap is correct

Bad fixes:

- `if missing then disable`
- `if host == alpine then do something different in Lua`
- `if binary broken then quietly skip feature`
- `if startup errors are ugly then hide them`

## Review Standard

Before merging a change that touches host dependencies, ask:

- Did this fix bootstrap, or did it only hide the error?
- Will Alpine and Fedora converge to the same runtime behavior?
- If bootstrap is missing, will the failure still be obvious?
- Did I preserve a truthful signal for the next engineer?

If any answer is "no", the change is not ready.

## Editing This File

When asked to update this document:

- prefer surgical edits over wholesale rewrites
- preserve the existing intent unless the user explicitly asks to replace it
- add clearer language, examples, and constraints instead of restarting from
  scratch

## Incident-Specific Note

In this repo, an earlier bad change masked markdown bootstrap problems by:

- disabling markdown rendering when parsers were missing
- suppressing markdown LSP startup on musl
- skipping parser setup when the CLI was absent or broken

That was incorrect because it made the editor safer but less truthful.

The correct response to that class of problem is:

- revert the masking
- repair bootstrap
- keep behavior identical across hosts
