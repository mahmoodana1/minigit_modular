#include "../../include/commands/MergeCommand.h"
#include <iostream>
#include <memory>
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
    std::string mergedIntoBranchLastCommitId =
        Utils::getLine(".minigit/heads/" + currentBranchName);
    // base of <merged> branch
    std::string mergedBranchBaseCommitId =
        Utils::getLine(".minigit/logs/heads/" + mergedBranchName)
            .substr(0, commitIdLength);

    if (mergedBranchBaseCommitId == mergedIntoBranchLastCommitId) {
        MergeCommand::fastForwardMerge(mergedBranchName);
    }
}

void MergeCommand::fastForwardMerge(const std::string &mergedBranchName) {
    fs::path indexDirPath = ".minigit/index";
    fs::path mergedBranchFilesTreePath =
        ".minigit/branchesFilesTree/" + mergedBranchName;

    std::string mergedIntoBranchName = Utils::getLine(".minigit/currentBranch");
    std::string commitId = GeneratorUtils::generateCommitId();

    // clear index Directory
    Utils::removeDir(indexDirPath);
    Utils::ensureDir(indexDirPath);

    // move the correct files to index
    Utils::copyDirRecursive(mergedBranchFilesTreePath, indexDirPath);

    CommitCommand::commit(commitId, mergedBranchName,
                          "Merged " + mergedBranchName + " into " +
                              mergedIntoBranchName);
    CommitCommand::headMove(mergedIntoBranchName, commitId);
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
