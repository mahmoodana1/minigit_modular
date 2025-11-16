#include "../../include/commands/MergeCommand.h"
#include <memory>

std::string MergeCommand::getName() { return "merge"; };

bool MergeCommand::checkArgs(const std::vector<std::string> &args) {
    return args.size() == 2;
}

void MergeCommand::description() {
    std::cout << R"(
Usage: minigit merge <branch>

Description:
  Merges the specified branch into the current branch.

Options:
  <branch>        The name of the branch you want to merge into the current branch.

Examples:
  minigit merge feature1
  minigit merge bugfix/login
  minigit merge main

Details:
  - Fast-forward merge happens when the current branch has no new commits; HEAD simply moves forward.
  - If conflicting changes are detected, merge stops and marks conflict files for user to fix.
  - Users must resolve conflicts manually and then run 'minigit merge' again to finalize the mrege.
  - Merge metadata is stored under .minigit/commits and updates the current branch ref in .minigit/heads.
)";
}

void MergeCommand::execute(const std::vector<std::string> &args) {}

namespace {
struct MergeCommandRegisterar {
    MergeCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "merge", std::make_unique<MergeCommand>());
    }
};
static MergeCommandRegisterar registerar;
} // namespace
