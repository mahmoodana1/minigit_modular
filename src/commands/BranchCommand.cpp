#include "../../include/commands/branchCommand.h"
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

std::string BranchCommand::getName() { return "branch"; }

bool BranchCommand::checkArgs(const std::vector<std::string> &args) {
    if (args.size() != 3 && args[1] != "new")
        return false;

    if (args.size() != 2 || args[1] == "new")
        return false;

    return true;
}

void BranchCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        std::cout << "Usage: minigit branch -<option>\n";
        return;
    }

    if (!Utils::exists(".minigit/currentBranch") ||
        !Utils::exists(".minigit/heads")) {
        std::cout << "Repository not initialized correctly\n";
    }

    return;
}

void BranchCommand::branchCommandsExecute(
    const std::vector<std::string> &args) {
    std::string command = args[0];

    if (command == "new") {
        std::string newBranchName = args[1];

        if (Utils::fileNameExists(fs::path(".minigit/heads"), newBranchName)) {
            std::cout << "Branch with name: " << newBranchName
                      << " Already exists";
            return;
        }

        fs::path currentBranchPath = fs::path(".minigit/currentBranch");
        std::string baseCommitId = Utils::getLine(currentBranchPath);
        Utils::clearAndPushLine(fs::path(".minigit/heads/" + newBranchName),
                                baseCommitId);
        Utils::clearAndPushLine(currentBranchPath, newBranchName);
    }
}

namespace {
struct BranchCommandRegisterar {
    BranchCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "commit", std::make_unique<BranchCommand>());
    }
    static BranchCommandRegisterar registerar;
};

} // namespace
