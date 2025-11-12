#include "../../include/commands/branchCommand.h"
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>

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

void BranchCommand::branchCommandsExecute(std::string command,
                                          std::string branchName) {
    if (command == "new") {
        if (Utils::fileNameExists(fs::path(".minigit/heads"), branchName)) {
            std::cout << "Branch with name: " << branchName
                      << " Already exists";
            return;
        }

        std::string baseCommitId = Utils::getLine(".minigit/currentBranch");
        Utils::clearAndPushLine(fs::path(".minigit/heads/" + branchName),
                                baseCommitId);
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
