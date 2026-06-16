# MiniGit

A from-scratch reimplementation of Git's core mechanics in C++17. Built to learn how version control actually works under the hood — staging, snapshots, refs, branches, and merging.

This is not a Git wrapper. It does not call `git` anywhere. All state lives under `.minigit/` and is manipulated with `std::filesystem`.

---

## Build

Requires a C++17 compiler. Tested with `g++` on Linux.

```bash
mkdir -p build
g++ -std=c++17 -Iinclude src/**/*.cpp -lstdc++fs -o build/minigit
```

Run from any directory you want to track:

```bash
./build/minigit <command> [args...]
```

---

## Commands

| Command | What it does |
|---|---|
| `init` | Create `.minigit/` scaffolding and the `main` branch |
| `add <path>` | Stage a file, or `add .` to stage the whole working dir |
| `commit -m <msg>` | Snapshot the index into a new commit on the current branch |
| `branch new <name>` | Create a branch from the current HEAD |
| `branch delete <name>` | Delete a branch (not `main`, not the active one) |
| `branch list all` | List every branch under `.minigit/heads` |
| `branch switch <name>` | Replace working tree with that branch's snapshot |
| `log` / `log all` | Show history for current branch, or for every branch |
| `status` | Compare working dir vs. index vs. last commit (colored output) |
| `merge <branch>` | Fast-forward if possible, otherwise prompt for an interactive merge |

Every command prints its own usage text when given bad args — just run it wrong and read the output.

---

## How a commit is stored

Each commit gets an ID of the form `YYYY-MM-DDTHH-MM-SSZ_<6 hex>` (UTC timestamp + a small random suffix — collisions would otherwise happen on commits made the same second).

```
.minigit/commits/<commit-id>/
  ├── snapshot/   # full copy of the staged files at commit time
  └── info        # metadata: message, author, timestamp
```

There is no content-addressed object store and no delta compression. Every commit is a full directory copy. That's the trade-off for keeping the code simple enough to read in one sitting.

---

## Repository layout

```
.minigit/
├── currentBranch         # plain text: name of the active branch
├── index/                # staging area — mirror of files added via `add`
├── commits/<id>/         # one folder per commit (snapshot + info)
├── heads/<branch>        # ref file: the commit ID at the tip of <branch>
├── branchesFilesTree/    # per-branch working-tree snapshots used by switch/merge
│   └── <branch>/...
├── logs/
│   ├── commits_refs      # global log: "<parent> <child> <branch>" per line
│   └── heads/<branch>    # per-branch log: "<parent> <child>" pairs
└── tmp/                  # scratch space for interactive merges
```

`heads/<branch>` is the closest thing to Git's `refs/heads/<branch>`. `branchesFilesTree/<branch>` is the bookkeeping trick that lets `switch` and `merge` rebuild a working tree without walking the commit chain.

---

## Architecture

The codebase is split into three layers:

```
include/  src/
├── commands/       # one class per CLI verb, inherits from Command
├── core/           # CommandRegistry (singleton)
└── utils/          # filesystem helpers + commit-id generator
```

### Command pattern

`Command` (in `include/commands/Command.h`) is a pure-virtual base:

```cpp
class Command {
  virtual bool checkArgs(const std::vector<std::string>&) = 0;
  virtual std::string getName() = 0;
  virtual void description() = 0;
  virtual void execute(const std::vector<std::string>&) = 0;
};
```

Each concrete command (e.g. `AddCommand`) self-registers at static-init time via an anonymous-namespace registrar struct:

```cpp
namespace {
struct AddCommandRegisterar {
    AddCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "add", std::make_unique<AddCommand>());
    }
};
static AddCommandRegisterar registerar;
}
```

`main.cpp` is then trivial — it just looks up `argv[1]` in the registry and calls `execute`. Adding a new command means writing one header + one source file; `main` never changes.

### Merge

`MergeCommand` inherits from `CommitCommand` so it can reuse `commit()`, `headMove()`, `pushToFilesTree()`, and `logCommit()` after producing the merged tree.

Two paths:
- **Fast-forward** — when the target branch's HEAD is an ancestor of the source's HEAD, the merge is just a pointer move plus a tree copy.
- **Indirect (interactive)** — when histories have diverged, the user is asked file-by-file which version to keep. The scratch work happens in `.minigit/tmp/`, then a normal merge commit is written.

There is no automatic 3-way text merge. Conflicts are resolved by you, manually, at the file level.

---

## Notes & limitations

- Each commit stores a full snapshot — disk usage grows linearly with commits.
- No remotes, no `clone`, no `push/pull`. This is a single-repo tool.
- Commit IDs aren't content hashes, so two identical trees produce different IDs.
- `switch` blows away unstaged changes after a `y/n` confirm — there is no stash.
- Tested on Linux. Windows would need `<filesystem>` linking adjustments and won't render the ANSI colors in `status` without a compatible terminal.

---

## Author

Mahmood AbuRmelh — Software Engineering student, embedded systems focus.

Built as a learning project to internalize how Git's data model works by re-deriving it.
