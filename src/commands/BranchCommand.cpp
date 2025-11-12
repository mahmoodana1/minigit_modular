#include "../../include/commands/branchCommand.h"
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

std::string BranchCommand::getName() { return "branch"; }

bool BranchCommand::checkArgs(const std::vector<std::string> &args) {
    if (args.size() > 3)
        return false;

    return true;
}

void BranchCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        std::cout << "Usage: minigit branch <option> [args ...]\n";
        return;
    }

    if (!Utils::exists(".minigit/currentBranch") ||
        !Utils::exists(".minigit/heads")) {
        std::cout << "Repository not initialized correctly\n";
    }

    branchCommandsExecute(args);
    return;
}

void BranchCommand::branchCommandsExecute(
    const std::vector<std::string> &args) {
    std::string command = args[1];

    if (command == "new") {
        std::string newBranchName = args[2];

        if (Utils::fileNameExists(fs::path(".minigit/heads"), newBranchName)) {
            std::cout << "Branch with name: " << newBranchName
                      << " Already exists";
            return;
        }

        fs::path currentBranchPath = fs::path(".minigit/currentBranch");
        std::string currentBranchName = Utils::getLine(currentBranchPath);
        std::string baseCommitId =
            Utils::getLine(".minigit/heads/" + currentBranchName);

        Utils::clearAndPushLine(fs::path(".minigit/heads/" + newBranchName),
                                baseCommitId);
        Utils::clearAndPushLine(currentBranchPath, newBranchName);
    }
}

namespace {
struct BranchCommandRegisterar {
    BranchCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "branch", std::make_unique<BranchCommand>());
    }
};
static BranchCommandRegisterar registerar;
} // namespace
