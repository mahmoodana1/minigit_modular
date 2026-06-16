#include "../../include/commands/MergeCommand.h"
#include <filesystem>
#include <iostream>
#include <string>

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
  - Users must resolve conflicts manually and then run 'minigit merge' again to finalize the merege.
  - Merge metadata is stored under .minigit/commits and updates the current branch ref in .minigit/heads.
)";
}

void MergeCommand::execute(const std::vector<std::string> &args) {
    // check branchesFilesTree for both <mergeged into> and <merged> folders
    // if there is new files from merged simply add them to the stagin area
    // if there are same files with different contents ask the uesr wich version
    // of the file he would liek to keep and add to staging area after all files
    // have been gone through, ask user for a merge commit message merge the
    // branches and commit a mergeCommit to the <merged into> branch make sure
    // to update the branchesFilesTree for <merged into> branch and head,
    // logs .....

    // is the <merged> branch base commit the last commit in the <merged into>
    // branch?
    if (!checkArgs(args)) {
        description();
        return;
    }

    int commitIdLength = 27;

    fs::path currentBranchPath = ".minigit/currentBranch";
    std::string currentBranchName = Utils::getLine(currentBranchPath);
    std::string mergedBranchName = args[1];

    if ((mergedBranchName == currentBranchName) ||
        !(Utils::fileNameExists(".minigit/heads", mergedBranchName))) {
        std::cout << "Select a valid Branch name.\n";
        description();
        return;
    }

    // head of current branch aka the <merged into> branch
    std::string mergedIntoBranchHead =
        Utils::getLine(".minigit/heads/" + currentBranchName);
    // base of <merged> branch
    std::string mergedBranchHead =
        Utils::getLine(".minigit/heads/" + mergedBranchName);

    if (mergedIntoBranchHead != mergedBranchHead) {
        bool canFastForward = true;
        for (const fs::directory_entry &entry :
             fs::recursive_directory_iterator(".minigit/branchesFilesTree/" +
                                              mergedBranchName)) {
            fs::path relativePath = fs::relative(
                entry.path(), ".minigit/branchesFilesTree/" + mergedBranchName);
            fs::path mergedIntoFilesTreePath =
                ".minigit/branchesFilesTree/" + currentBranchName;

            if (fs::is_regular_file(entry.path())) {
                if (fs::is_regular_file(mergedIntoFilesTreePath /
                                        relativePath)) {
                    if (Utils::checkFileBigger(mergedIntoFilesTreePath /
                                                   relativePath,
                                               entry.path())) {
                        canFastForward = false;
                        break;
                    }
                }
            }
        }

        if (canFastForward) {
            MergeCommand::fastForwardMerge(currentBranchName, mergedBranchName);
        } else {
            std::cout << "You cannot do Fast-forward merge. \n";
            std::string userAnswear = "e";
            std::cout
                << "Do you want to Choose witch files do you wanna keep form "
                   "both branches,\nor Merge over Current Branch Commits (y, "
                   "n) ?\ny - Choose witch files to keep.\nn - Merge Over.\ne "
                   "- exit.\n";
            std::getline(std::cin, userAnswear);

            if (userAnswear == "n") {
                fastForwardMerge(currentBranchName, mergedBranchName);
            } else if (userAnswear == "y") {
                /*
                steps to do this:
                    move the whole "branchesFilesTree" from the mereged branch
                to the index, check the "branchesFilesTree" form the
                mergedIntoBranch if there are same files with different sizes
                then ask the user witch version he wants to keep. use tmp folder
                .
                */
                MergeCommand::indirectMerge(currentBranchName,
                                            mergedBranchName);
            } else if (userAnswear == "e") {
                std::cout << "Exited merge succesfully.\n";
            } else {
                std::cout << "Invalid input.\n";
            }
        }
    } else {
        std::cout << "Branches are in sync.\n";
    }
    return;
}

void MergeCommand::fastForwardMerge(const std::string &mergedIntoBranchName,
                                    const std::string &mergedBranchName) {

    fs::path mergedBranchFilesTreePath =
        ".minigit/branchesFilesTree/" + mergedBranchName;

    fs::path mergedIntoBranchHeadLogs =
        ".minigit/logs/heads/" + mergedIntoBranchName;
    fs::path mergedBranchHeadLogs = ".minigit/logs/heads/" + mergedBranchName;

    fs::copy_file(".minigit/heads/" + mergedBranchName,
                  ".minigit/heads/" + mergedIntoBranchName,
                  fs::copy_options::overwrite_existing);
    fs::copy_file(".minigit/logs/heads/" + mergedBranchName,
                  ".minigit/logs/heads/" + mergedIntoBranchName,
                  fs::copy_options::overwrite_existing);

    // sync branchesFilesTree
    Utils::copyDirRecursive(mergedBranchFilesTreePath, ".");
    Utils::copyDirRecursive(".", ".minigit/branchesFilesTree/" +
                                     mergedIntoBranchName);
    Utils::copyDirRecursive(".", mergedBranchFilesTreePath);

    std::cout << "Fast-forward merged into " << mergedIntoBranchName << ".\n";
}

void MergeCommand ::indirectMerge(const std::string &mergedIntoBranchName,
                                  const std::string &mergedBranchName) {
    fs::path mgitTmp = ".minigit/tmp";
    std::string commitId = GeneratorUtils::generateCommitId();

    Utils::removeDir(mgitTmp);
    Utils::ensureDir(mgitTmp);

    Utils::copyDirRecursive(".minigit/branchesFilesTree/" + mergedBranchName,
                            mgitTmp);
    for (const fs::directory_entry &entry :
         fs::recursive_directory_iterator(mgitTmp)) {
        fs::path relativeFilePath = fs::relative(entry.path(), mgitTmp);

        if (fs::is_regular_file(relativeFilePath) &&
            !Utils::checkFilesEqual(relativeFilePath, entry.path())) {
            std::string userAnswear = "a";
            std::cout << "Conflict fount in file: "
                      << mgitTmp.filename().string() << ".\n";
            std::cout << "Witch version do you wanna keep --default is a, "
                         "(a, b)?\n";
            std::cout << "a - " << mergedIntoBranchName << " version.\n"
                      << "b - " << mergedBranchName << " version.\n"
                      << "e - " << "exit.\n";
            std::getline(std::cin, userAnswear);

            if (userAnswear == "a") {
                Utils::copyFileSafe(relativeFilePath, mgitTmp);
                std::cout << relativeFilePath.filename().string() << " --> "
                          << mergedIntoBranchName << ".\n";
            } else if (userAnswear == "b") {
                std::cout << relativeFilePath.filename().string() << " --> "
                          << mergedBranchName << ".\n";
            } else if (userAnswear == "e") {
                return;
            } else {
                std::cout << "Invalid Choice.\n";
                return;
            }
        }
    }

    std::string message;
    do {
        std::cout << "Merge message: ";
        std::getline(std::cin, message);
    } while (message.empty());

    // commit the changes to both branches
    Utils::copyDirRecursive(mgitTmp, ".minigit/index");
    CommitCommand::commit(commitId, mergedBranchName, message);
    Utils::copyDirRecursive(mgitTmp, ".minigit/index");
    CommitCommand::commit(commitId, mergedIntoBranchName, message);
}

namespace {
struct MergeCommandRegisterar {
    MergeCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "merge", std::make_unique<MergeCommand>());
    }
};
static MergeCommandRegisterar registerar;
} // namespace
