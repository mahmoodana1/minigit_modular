#include "../../include/commands/branchCommand.h"
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

std::string BranchCommand::getName() { return "branch"; }

bool BranchCommand::checkArgs(const std::vector<std::string> &args) {
    if (args.size() != 3) {
        return false;
    }

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

        return;
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
                      << " Already exists\n";
            return;
        }

        fs::path currentBranchPath = fs::path(".minigit/currentBranch");
        std::string currentBranchName = Utils::getLine(currentBranchPath);
        std::string baseCommitId =
            Utils::getLine(".minigit/heads/" + currentBranchName);

        Utils::clearAndPushLine(fs::path(".minigit/heads/" + newBranchName),
                                baseCommitId);
        Utils::clearAndPushLine(currentBranchPath, newBranchName);

        return;

    } else if (command == "delete") {
        fs::path currentBranchPath = fs::path(".minigit/currentBranch");
        std::string currentBranchName = Utils::getLine(currentBranchPath);
        std::string wannaDeleteBranch = args[2];

        if (wannaDeleteBranch == currentBranchName) {
            std::cout << "Cannot Delete the branch you are on.\n";
            return;
        }

        fs::path branchFilePath = ".minigit/heads/" + wannaDeleteBranch;
        if (fs::remove(branchFilePath)) {
            std::cout << "Branch: " << wannaDeleteBranch
                      << " Deleted successfully.\n";
        } else {
            std::cout << "Branch not found.\n";
        }

        return;

    } else if (command == "list") {
        if (args[2] == "all") {
            fs::path headsDir = ".minigit/heads";

            std::cout << "Branches: \n";
            Utils::printFilesInDirectory(headsDir, true);

            return;
        }
    }
    // flags integraion
    //
    //

    std::cout << "Usage: branch <option> [args ...]\n";
    return;
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
