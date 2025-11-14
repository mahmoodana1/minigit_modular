#include "../../include/commands/StatusCommand.h"
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <sys/types.h>
#include <vector>

std::string StatusCommand::getName() { return "add"; }

bool StatusCommand::checkArgs(const std::vector<std::string> &args) {
    return (args.size() == 1);
}

void StatusCommand::description() {
    std::cout << R"(
Usage: minigit status

Description:
  Shows the current working tree status:
    - Files that have been modified since the last 'add'
    - New files not in the index
    - Files staged in .minigit/index
    - Files removed from the working directory

Details:
  The status command compares:
    1. The working directory (.)
    2. The staging area (.minigit/index)

Examples:
  minigit status
)";
}

std::vector<std::string> StatusCommand::compareRoorToIndex() {
    std::vector<std::string> untrackedPaths;
    std::vector<std::string> rootPaths;
    std::vector<std::string> indexPaths;

    for (const fs::directory_entry &entry :
         fs::recursive_directory_iterator(".")) {
        if ((entry.path().string().find(".git") != 0)) {
            continue;
        }
        rootPaths.push_back(entry.path());
    }

    for (const fs::directory_entry &entry :
         fs::recursive_directory_iterator(".minigit/index")) {
        indexPaths.push_back(entry.path());
    }

    std::cout << "Root Paths: \n";
    for (int i = 0; i < rootPaths.size(); i++) {
        std::cout << rootPaths[i] << '\n';
    }

    std::cout << "Index Paths: \n";
    for (int i = 0; i < indexPaths.size(); i++) {
        std::cout << indexPaths[i] << '\n';
    }

    return untrackedPaths;
}

void StatusCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        description();
        return;
    }

    StatusCommand::compareRoorToIndex();
}

namespace {
struct StatusCommandRegisterar {
    StatusCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "status", std::make_unique<StatusCommand>());
    }
};
static StatusCommandRegisterar registerar;
} // namespace
