gh-pr-repl
==========

[GitHub-Cli extension](https://cli.github.com/manual/gh_extension).

Provide a simple REPL for the selected PRs.

You'd need this if PRs are part of your workflow and you dislike pointing and clicking.

# Installation

```shell
$ gh extension install nobe4/gh-pr-repl
```

## Requirements

- Ruby
- `pbcopy`
- `open`
- `tmux`

# Usage

With a single branch:

```shell
$ gh pr-repl
# Will use the PR associated with the current branch.

$ gh pr-repl cli/cli/demo-branch
# Will use the PR associated with https://github.com/cli/cli/tree/demo-branch

$ gh pr-repl https://github.com/cli/cli/pull/1
# Will use https://github.com/cli/cli/pull/1
```

With many branches:

```shell
$ gh pr-repl cli/cli/demo-branch https://github.com/cli/cli/pull/1
# Will use the PR associated with https://github.com/cli/cli/tree/demo-branch
# and https://github.com/cli/cli/pull/1
```

Getting help:

```shell
$ gh pr-repl
cli/cli/demobranch > h
# shows the help
```

# Development and contributing

Some ideas:

- [ ] Adding formatting checks in an action.
- [ ] Adding contribution guide.
- [ ] Adding specs.
- [ ] Removing `pbcopy` dependency.
- [ ] Removing `tmux` dependency.
- [ ] Having a better way to define commands, i.e. not in `@@commands` and as methods later.
- [ ] _Add more_
