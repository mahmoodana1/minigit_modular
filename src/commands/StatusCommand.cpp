#include "../../include/commands/StatusCommand.h"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <sys/types.h>
#include <utility>
#include <vector>

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

std::vector<std::pair<fs::path, std::string>> StatusCommand::compareFiles() {
    std::vector<std::pair<fs::path, std::string>> result;
    std::vector<fs::path> rootPaths;
    std::vector<fs::path> indexPaths;
    std::vector<fs::path> lastCommitPaths;

    std::string currentBranchName = Utils::getLine(".minigit/currentBranch");
    std::string lastCommitId =
        Utils::getLine(".minigit/heads/" + currentBranchName);
    fs::path lastCommitFilesPaths =
        fs::path(".minigit/commits/" + lastCommitId + "/snapshot");

    for (const fs::directory_entry &entry :
         fs::recursive_directory_iterator(".")) {
        if (Utils::startsWith(entry.path().string(), "./.git") ||
            Utils::startsWith(entry.path().string(), "./.minigit")) {
            continue;
        }
        if (entry.is_regular_file())
            rootPaths.push_back(entry.path());
    }

    for (const fs::directory_entry &entry :
         fs::recursive_directory_iterator(".minigit/index")) {
        if (entry.is_regular_file())
            indexPaths.push_back(entry.path());
    }

    for (const fs::directory_entry &entry :
         fs::recursive_directory_iterator(lastCommitFilesPaths)) {
        if (entry.is_regular_file())
            lastCommitPaths.push_back(entry.path());
    }

    for (int i = 0; i < rootPaths.size(); i++) {
        bool found = false;
        for (int k = 0; k < lastCommitPaths.size(); k++) {
            if (rootPaths[i].filename() == lastCommitPaths[k].filename()) {
                if (!StatusCommand::checkFilesEqual(rootPaths[i],
                                                    lastCommitPaths[k])) {
                    result.push_back({rootPaths[i], "changed"});
                    found = true;
                }
            }
        }

        if (!found) {
            result.push_back({rootPaths[i], "untracked"});
        }
    }

    for (int i = 0; i < rootPaths.size(); i++) {
        for (int k = 0; k < lastCommitPaths.size(); k++) {
            if (rootPaths[i].filename() == lastCommitPaths[k].filename()) {
                if (!StatusCommand::checkFilesEqual(rootPaths[i],
                                                    lastCommitPaths[k])) {
                    result.push_back({rootPaths[i], "deleted"});
                }
            }
        }
    }

    return result;
}

void StatusCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        description();
        return;
    }

    StatusCommand::compareFiles();
}

bool checkFilesEqual(const fs::path &path1, const fs::path path2) {
    if (fs::file_size(path1) != fs::file_size(path2)) {
        return false;
    }

    std::ifstream fa(path1, std::ios::binary);
    std::ifstream fb(path2, std::ios::binary);

    if (!fa || !fb)
        return false;

    std::istreambuf_iterator<char> ita(fa);
    std::istreambuf_iterator<char> itb(fb);
    std::istreambuf_iterator<char> end;

    return std::equal(ita, end, itb);
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
