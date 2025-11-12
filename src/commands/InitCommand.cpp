
#include "../../include/commands/InitCommand.h"
#include <iostream>
#include <string>
#include <vector>

std::string InitCommand::getName() { return "init"; }

bool InitCommand::checkArgs(const std::vector<std::string> &args) {
    if (args.size() > 1)
        return false;
    return true;
}

void InitCommand::description() {
    std::cout << R"(
Usage: minigit init

Description:
  Initializes a new MiniGit repository in the current directory.

Details:
  Creates the .minigit directory structure with subfolders:
    - index/
    - commits/
    - logs/
    - heads/
  Sets up the default branch 'main' and HEAD reference.

Example:
  minigit init
)";
}

void InitCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        description();
        return;
    }

    if (Utils::exists(".minigit")) {
        std::cout << "Repository already initialized.\n";
        return;
    }

    Utils::ensureDir(".minigit");
    Utils::ensureDir(".minigit/index");
    Utils::ensureDir(".minigit/commits");
    Utils::ensureDir(".minigit/logs");
    Utils::ensureDir(".minigit/heads");

    Utils::clearAndPushLine(".minigit/currentBranch", "main");
    Utils::clearAndPushLine(".minigit/heads/main", "none");

    std::cout << "Initialized empty MiniGit repository.\n";
}

namespace {
struct InitCommandRegistrar {
    InitCommandRegistrar() {
        CommandRegistry::getInstance().registerCommand(
            "init", std::make_unique<InitCommand>());
    }
};
static InitCommandRegistrar registrar;
} // namespace
