#include "../../include/commands/LogCommand.h"
#include <iostream>
#include <memory>

std::string LogCommand::getName() { return "log"; }

bool LogCommand::checkArgs(const std::vector<std::string> &args) {
    return (args.size() <= 2);
}

void LogCommand::description() {
    std::cout << R"(
Usage: minigit log [option]

Description:
  Shows commit history.

Options:
  (no option)     Show commit history for the current branch only.
  all             Show commit history from all branches.

Examples:
  minigit log
  minigit log all

Details:
  - By default, logs are shown for the active branch (based on .minigit/currentBranch).
  - 'log all' walks through every branch under .minigit/heads and prints every commit found.
  - Each commit displays: ID, message, author, date, and files.
)";
}

void LogCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        description();
        return;
    }

    if (args.size() == 2 && args[1] == "all") {
        std::cout << "All Logs\n";

    } else if (args.size() == 1) {
        std::cout << "Branch Logs\n";
    } else {
        description();
    }

    return;
}

namespace {
struct LogCommandRegisterar {
    LogCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "log", std::make_unique<LogCommand>());
    }
};
static LogCommandRegisterar registerar;
} // namespace
