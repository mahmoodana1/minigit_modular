#include "../../include/commands/StatusCommand.h"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <sys/types.h>
#include <utility>
#include <vector>

std::string StatusCommand::getName() { return "add"; }

bool StatusCommand::checkArgs(const std::vector<std::string> &args) {
    return (args.size() == 1);
}

struct FilesRootIndexCommit {
    bool inRoot = false;
    bool inIndex = false;
    bool inLastCommit = false;
};

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
    3. The last commit snapshot (.minigit/commits/<id>/snapshot)

Examples:
  minigit status
)";
}

std::vector<std::pair<fs::path, std::string>> StatusCommand::compareFiles() {
    std::vector<std::pair<fs::path, std::string>> result;
    std::map<fs::path, FilesRootIndexCommit> comparisonMap;

    std::string currentBranchName = Utils::getLine(".minigit/currentBranch");
    std::string lastCommitId =
        Utils::getLine(".minigit/heads/" + currentBranchName);

    fs::path lastCommitFilesPaths =
        fs::path(".minigit/commits/" + lastCommitId + "/snapshot/");

    for (const auto &entry : fs::recursive_directory_iterator(".")) {
        if (Utils::startsWith(entry.path().string(), "./.git/") ||
            Utils::startsWith(entry.path().string(), "./.minigit/"))
            continue;

        if (entry.is_regular_file()) {
            comparisonMap[fs::relative(entry.path(), ".")].inRoot = true;
        }
    }

    for (const auto &entry :
         fs::recursive_directory_iterator(".minigit/index")) {
        if (entry.is_regular_file()) {
            comparisonMap[fs::relative(entry.path(), ".minigit/index")]
                .inIndex = true;
        }
    }

    for (const auto &entry :
         fs::recursive_directory_iterator(lastCommitFilesPaths)) {
        if (entry.is_regular_file()) {
            comparisonMap[fs::relative(entry.path(), lastCommitFilesPaths)]
                .inLastCommit = true;
        }
    }

    // classification
    for (const auto &node : comparisonMap) {
        const fs::path &filePath = node.first;

        bool inRoot = node.second.inRoot;
        bool inIndex = node.second.inIndex;
        bool inCommit = node.second.inLastCommit;

        fs::path rootPath = filePath;
        fs::path indexPath = ".minigit/index/" + filePath.string();
        fs::path commitPath = lastCommitFilesPaths / filePath;

        std::string status;

        // untracked
        if (inRoot && !inIndex && !inCommit) {
            status = "untracked";
        }
        // new file staged
        else if (inRoot && inIndex && !inCommit) {
            status = "new file staged";
        }
        // deleted but not staged
        else if (!inRoot && inIndex && inCommit) {
            status = "deleted";
        }
        // staged for removal
        else if (!inRoot && !inIndex && inCommit) {
            status = "staged for removal";
        }
        // conflict
        else if (!inRoot && inIndex && !inCommit) {
            status = "conflict";
        }
        // clean or modified
        else if (inRoot && !inIndex && inCommit) {
            if (checkFilesEqual(rootPath, commitPath)) {
                status = "clean";
            } else {
                status = "modified";
            }
        }
        // compare tracked files
        else if (inRoot && inIndex && inCommit) {

            bool rootVsIndex =
                StatusCommand::checkFilesEqual(rootPath, indexPath);
            bool indexVsCommit =
                StatusCommand::checkFilesEqual(indexPath, commitPath);

            if (!rootVsIndex && indexVsCommit) {
                status = "modified"; // working tree modified, not staged
            } else if (!indexVsCommit) {
                status = "staged"; // staged but different from commit
            } else {
                status = "clean"; // no changes
            }
        } else {
            status = "unknown state";
        }

        result.push_back({filePath, status});
    }

    for (auto &entry : result) {
        std::cout << entry.first << " : " << entry.second << '\n';
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

bool StatusCommand::checkFilesEqual(const fs::path &path1,
                                    const fs::path &path2) {
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
