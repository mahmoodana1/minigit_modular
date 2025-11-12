#include "../../include/commands/branchCommand.h"
#include "../../include/utils/utils.h"
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

std::string BranchCommand::getName() { return "branch"; }

bool BranchCommand::checkArgs(const std::vector<std::string> &args) {
    return args.size() >= 2;
}

void BranchCommand::description() {
    std::cout << R"(
Usage: minigit branch <option> [args ...]

Options:
  new <branch_name>       Create a new branch based on the current branch.
  delete <branch_name>    Delete an existing branch (cannot delete 'main' or current).
  list all                List all existing branches.

Examples:
  minigit branch new featureX
  minigit branch delete featureX
  minigit branch list all
)";
}

void BranchCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        description();
        return;
    }

    if (!Utils::exists(".minigit/currentBranch") ||
        !Utils::exists(".minigit/heads")) {
        std::cout << "Repository not initialized correctly.\n";
        return;
    }

    branchCommandsExecute(args);
}

void BranchCommand::branchCommandsExecute(
    const std::vector<std::string> &args) {
    std::string command = args[1];
    fs::path currentBranchPath = fs::path(".minigit/currentBranch");
    std::string currentBranchName = Utils::getLine(currentBranchPath);

    if (command == "new") {
        if (args.size() < 3) {
            std::cout << "Missing branch name.\n";
            description();
            return;
        }

        std::string newBranchName = args[2];

        if (Utils::fileNameExists(fs::path(".minigit/heads"), newBranchName)) {
            std::cout << "Branch with name '" << newBranchName
                      << "' already exists.\n";
            return;
        }

        std::string baseCommitId =
            Utils::getLine(".minigit/heads/" + currentBranchName);

        // create new branch file pointing to same commit as current branch
        Utils::clearAndPushLine(fs::path(".minigit/heads/" + newBranchName),
                                baseCommitId);

        std::cout << "Branch '" << newBranchName << "' created successfully.\n";
        return;
    }

    else if (command == "delete") {
        if (args.size() < 3) {
            std::cout << "Missing branch name.\n";
            description();
            return;
        }

        std::string wannaDeleteBranch = args[2];

        if (wannaDeleteBranch == "main") {
            std::cout << "You cannot delete the 'main' branch.\n";
            return;
        }

        if (wannaDeleteBranch == currentBranchName) {
            std::cout << "Cannot delete the branch you are currently on.\n";
            return;
        }

        fs::path branchFilePath = ".minigit/heads/" + wannaDeleteBranch;
        if (fs::remove(branchFilePath)) {
            std::cout << "Branch '" << wannaDeleteBranch
                      << "' deleted successfully.\n";
        } else {
            std::cout << "Branch not found.\n";
        }

        return;
    }

    else if (command == "list") {
        if (args.size() >= 3 && args[2] == "all") {
            fs::path headsDir = ".minigit/heads";
            std::cout << "Branches:\n";
            Utils::printFilesInDirectory(headsDir, true);
            return;
        }

        std::cout << "Invalid usage of 'list'.\n";
        description();
        return;
    }

    else if (command == "switch") {
        fs::path headsDir = ".minigit/heads";

        if (args.size() >= 3) {
            std::string switchedToBranch = args[2];
            if (Utils::fileNameExists(headsDir, switchedToBranch)) {
                Utils::clearAndPushLine(currentBranchPath, switchedToBranch);
                std::cout << "Active Branch: " << switchedToBranch << '\n';
                return;
            } else {
                std::cout << "Branch '" << switchedToBranch << "' not found.\n";
                return;
            }
        }

        std::cout << "Invalid usage of 'switch'.\n";
        description();
        return;
    }

    else {
        std::cout << "Unknown branch option: " << command << "\n";
        description();
        return;
    }
}
namespace {

struct BranchCommandRegistrar {
    BranchCommandRegistrar() {
        CommandRegistry::getInstance().registerCommand(
            "branch", std::make_unique<BranchCommand>());
    }
};
static BranchCommandRegistrar registrar;
} // namespace
