#include "../../include/commands/StatusCommand.h"
#include <iostream>
#include <memory>
#include <string>
#include <sys/types.h>

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

void StatusCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        description();
        return;
    }
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
