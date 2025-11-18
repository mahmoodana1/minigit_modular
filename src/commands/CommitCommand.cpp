#include "../../include/commands/CommitCommand.h"
#include "../../include/utils/GeneratorUtils.h"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

std::string getCommitMessage(const std::vector<std::string> &args) {
    std::ostringstream messageStream;
    for (int i = 2; i < args.size(); i++) {
        messageStream << args[i] << ' ';
    }
    return messageStream.str();
}

std::string CommitCommand::getName() { return "commit"; }

bool CommitCommand::checkArgs(const std::vector<std::string> &args) {
    if (args.size() < 3 || args[1] != "-m")
        return false;
    return true;
}

void CommitCommand::description() {
    std::cout << R"(
Usage: minigit commit -m <message>

Description:
  Records changes from the staging area (index) into a new commit.

Examples:
  minigit commit -m Initial commit
  minigit commit -m Fix bug in AddCommand
)";
}

void CommitCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        description();
        return;
    }

    if (!Utils::exists(".minigit") || !Utils::exists(".minigit/index")) {
        std::cout << "Repository not initialized correctly\n";
        return;
    }

    std::string commitId = GeneratorUtils::generateCommitId();

    fs::path src = fs::path(".minigit/index");
    fs::path commitPath =
        fs::path(".minigit/commits/" + commitId + "/snapshot");

    if (fs::is_empty(src)) {
        std::cout
            << "You cannot commit an empty index directory, make sure you have "
               "added files to the staging directory with:\n"
               "./build/minigit add <options>\n";
        return;
    }
    fs::path currentBranchPath = ".minigit/currentBranch";
    std::string currentBranchName = Utils::getLine(currentBranchPath);
    std::string commitMessage = getCommitMessage(args);

    CommitCommand::commit(commitId, currentBranchName, commitMessage);
}

void CommitCommand::commit(const std::string commitId,
                           const std::string branchName,
                           const std::string &commitMessage) {
    fs::path src = fs::path(".minigit/index");
    fs::path commitPath =
        fs::path(".minigit/commits/" + commitId + "/snapshot");

    pushToFilesTree(branchName);

    Utils::ensureDir(commitPath);
    Utils::copyDirRecursive(src, commitPath, false);
    Utils::removeDir(src);
    Utils::ensureDir(src);

    CommitCommand::logCommit(commitMessage, commitId, branchName);

    // headMoves after refs logging
    headMove(branchName, commitId);
}
void CommitCommand::logCommit(const std::string &commitMessage,
                              const std::string &commitId,
                              const std::string &branchName) {
    // info file
    std::ofstream info(".minigit/commits/" + commitId + "/info");
    fs::path commitPath =
        fs::path(".minigit/commits/" + commitId + "/snapshot");

    if (info.is_open()) {
        info << "Commit ID: " << commitId << "\n";
        info << "Message: "
             << (!commitMessage.empty() ? commitMessage : "(no message)")
             << "\n";
        info << "Author: " << std::getenv("USER") << "\n";
        info << "Date: " << GeneratorUtils::getCurrentTimeUTC() << "\n";
        info << "Files committed:\n";
        for (const auto &entry : fs::recursive_directory_iterator(commitPath)) {
            if (fs::is_regular_file(entry))
                info << "  - "
                     << fs::relative(entry.path(), commitPath).string() << "\n";
        }
    }

    // refs : refrences file
    std::string previousCommitId =
        Utils::getLine(fs::path(".minigit/heads/" + branchName));
    std::ofstream refs(".minigit/commits/" + commitId + "/refs");

    if (refs.is_open()) {
        refs << "Previous Commit ID: " << previousCommitId << '\n';
        refs << "Commit ID: " << commitId;
    }

    std::cout << "Commit pushed to commits directory with id: " << commitId
              << '\n';
    // logs: append commit to logs file
    Utils::ensureDir(fs::path(".minigit/logs/heads"));
    std::ofstream commits_refs(".minigit/logs/commits_refs", std::ios::app);

    if (!commits_refs) {
        std::cout << "Failed to open '.minigit/logs/commits_refs'.\n";
        return;
    }
    commits_refs << previousCommitId << ' ' << commitId << ' ' << branchName
                 << "\n";

    std::ofstream heads(".minigit/logs/heads/" + branchName, std::ios::app);
    if (!commits_refs) {
        std::cout << "Failed to open '.minigit/logs/heads/" << branchName
                  << "' \n";
        return;
    }
    heads << previousCommitId << ' ' << commitId << " \n";
}
void CommitCommand::headMove(std::string branchName, std::string commitId) {
    Utils::ensureDir(".minigit/heads");
    fs::path headPath = ".minigit/heads/" + branchName;
    std::string firstLine = Utils::getLine(headPath);
    Utils::clearAndPushLine(headPath, commitId);
}

void CommitCommand::pushToFilesTree(const std::string &branchName) {

    Utils::ensureDir(".minigit/branchesFilesTree/" + branchName);

    Utils::copyDirRecursive(".minigit/index",
                            ".minigit/branchesFilesTree/" + branchName);

    for (const fs::directory_entry &entry : fs::recursive_directory_iterator(
             ".minigit/branchesFilesTree/" + branchName)) {
        fs::path relativePath = fs::relative(
            entry.path(), ".minigit/branchesFilesTree/" + branchName);

        if (fs::is_regular_file(entry.path())) {
            if (!fs::exists(relativePath)) {
                fs::remove(entry.path());
            }
        }
    }
}

namespace {
struct CommitCommandRegisterar {
    CommitCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "commit", std::make_unique<CommitCommand>());
    }
};
static CommitCommandRegisterar registerar;
} // namespace
