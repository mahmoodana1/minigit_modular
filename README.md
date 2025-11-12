# 🧩 MiniGit

**MiniGit** is a lightweight, educational version control system written in **modern C++17**.  
It replicates Git’s core behavior — staging, committing, and branching — entirely using the C++ standard library and `std::filesystem`.

---

## 🚀 Features

- 🏗️ **Initialize Repository** – `minigit init`
- 📦 **Stage Files & Directories** – `minigit add <path>`
- 🧾 **Commit Changes** – `minigit commit -m "message"`
- 🌿 **Create, Delete, and List Branches** – `minigit branch <option> [args...]`
- 🔄 **Switch Between Branches** – `minigit switch <branch_name>`
- 🧠 **Command Registry System** – dynamically registers all commands
- 💾 **Filesystem-based Commits** – each commit stores snapshot + metadata
- ⚙️ **Future Expansion Ready** – supports adding merge and log systems later

---

## 🧰 Quick Setup

### 🧱 Build
Make sure you have a C++17 compiler (like `g++`) and a Linux or WSL terminal.

```bash
mkdir -p build
g++ -std=c++17 -Iinclude src/**/*.cpp -lstdc++fs -o build/minigit

▶️ Run

./build/minigit <command> [options]

Example:

./build/minigit init
./build/minigit add .
./build/minigit commit -m "Initial commit"
./build/minigit branch new dev
./build/minigit switch dev

📜 Command Summary
Command	Description	Example
minigit init	Initialize new repository	minigit init
minigit add <path>	Stage files or directories	minigit add .
minigit commit -m "msg"	Create a new commit	minigit commit -m "Fix bug"
minigit branch new <name>	Create new branch	minigit branch new featureX
minigit branch delete <name>	Delete branch	minigit branch delete featureX
minigit branch list all	List all branches	minigit branch list all
minigit switch <branch>	Switch to another branch	minigit switch dev
🧩 Repository Structure

.minigit/
├── commits/           # Commit snapshots + info
├── index/             # Staging area
├── heads/             # Branch references
├── currentBranch      # Tracks active branch
└── logs/              # Future commit logs

🧠 Technical Highlights

    Modern C++17 only – uses std::filesystem, std::vector, std::unique_ptr

    Command Pattern – every command self-registers using a singleton CommandRegistry

    Branch Architecture – mimics Git’s HEAD and refs/heads system

    Structured Output – clear terminal messages for every operation

    Easily Extensible – add new commands with minimal integration effort

👨‍💻 Author

Mahmood AbuRmelh
🎓 Software Engineering Student — Embedded Systems Focus
🔧 C++ / Git Internals / Filesystem Engineering
🌍 GitHub Profile
📄 License

Released under the MIT License — free for personal and educational use.

MiniGit — Learn version control by building it yourself.
