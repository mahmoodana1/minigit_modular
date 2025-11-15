#include "../../include/commands/StatusCommand.h"
#include <filesystem>
#include <fstream>
#include <iomanip>
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

// Color codes that work on most terminals
namespace Colors {
// ANSI color codes
constexpr const char *RESET = "\033[0m";
constexpr const char *RED = "\033[31m";
constexpr const char *GREEN = "\033[32m";
constexpr const char *YELLOW = "\033[33m";
constexpr const char *BLUE = "\033[34m";
constexpr const char *MAGENTA = "\033[35m";
constexpr const char *CYAN = "\033[36m";
constexpr const char *WHITE = "\033[37m";
constexpr const char *BRIGHT_RED = "\033[91m";
constexpr const char *BRIGHT_GREEN = "\033[92m";
constexpr const char *BRIGHT_YELLOW = "\033[93m";
constexpr const char *BRIGHT_CYAN = "\033[96m";

// Check if terminal supports colors
static bool supportsColor() {
#ifdef _WIN32
    // Windows 10+ supports ANSI codes
    return true;
#else
    // Unix-like systems
    const char *term = std::getenv("TERM");
    return term && std::string(term) != "dumb";
#endif
}
} // namespace Colors

// Get color based on status
std::string getStatusColor(const std::string &status) {
    if (status == "untracked")
        return Colors::BRIGHT_RED;
    if (status == "new file staged")
        return Colors::BRIGHT_GREEN;
    if (status == "deleted")
        return Colors::RED;
    if (status == "staged for removal")
        return Colors::YELLOW;
    if (status == "conflict")
        return Colors::BRIGHT_RED;
    if (status == "clean")
        return Colors::GREEN;
    if (status == "modified")
        return Colors::YELLOW;
    if (status == "staged")
        return Colors::BRIGHT_CYAN;
    return Colors::WHITE;
}

// Get status symbol for visual distinction
std::string getStatusSymbol(const std::string &status) {
    if (status == "untracked")
        return "?";
    if (status == "new file staged")
        return "+";
    if (status == "deleted")
        return "-";
    if (status == "staged for removal")
        return "✕";
    if (status == "conflict")
        return "!";
    if (status == "clean")
        return "✓";
    if (status == "modified")
        return "M";
    if (status == "staged")
        return "●";
    return "~";
}

void printResults(const std::vector<std::pair<fs::path, std::string>> &result) {
    bool useColors = Colors::supportsColor();

    // Calculate max path length for alignment
    size_t maxPathLen = 0;
    size_t maxStatusLen = 0;

    for (const auto &entry : result) {
        maxPathLen = std::max(maxPathLen, entry.first.string().length());
        maxStatusLen = std::max(maxStatusLen, entry.second.length());
    }

    // Add padding
    maxPathLen = std::min(maxPathLen + 2, size_t(60)); // Cap at 60 chars
    maxStatusLen += 2;

    // Print header
    std::cout << "\n";
    if (useColors) {
        std::cout << Colors::CYAN;
    }
    std::cout << std::string(maxPathLen + maxStatusLen + 8, '-') << "\n";
    std::cout << std::left << std::setw(maxPathLen) << "File Path"
              << "│ " << std::setw(maxStatusLen) << "Status"
              << "│ Symbol\n";
    std::cout << std::string(maxPathLen + maxStatusLen + 8, '-') << "\n";
    if (useColors) {
        std::cout << Colors::RESET;
    }

    // Print entries
    for (const auto &entry : result) {
        std::string filePath = entry.first.string();
        const std::string &status = entry.second;
        std::string symbol = getStatusSymbol(status);

        // Truncate long paths
        if (filePath.length() > 60) {
            filePath = "..." + filePath.substr(filePath.length() - 57);
        }

        std::cout << std::left << std::setw(maxPathLen) << filePath << "│ ";

        if (useColors) {
            std::cout << getStatusColor(status);
        }
        std::cout << std::left << std::setw(maxStatusLen) << status;
        if (useColors) {
            std::cout << Colors::RESET;
        }

        std::cout << "│ ";
        if (useColors) {
            std::cout << getStatusColor(status);
        }
        std::cout << symbol;
        if (useColors) {
            std::cout << Colors::RESET;
        }
        std::cout << "\n";
    }

    // Print footer
    if (useColors) {
        std::cout << Colors::CYAN;
    }
    std::cout << std::string(maxPathLen + maxStatusLen + 8, '-') << "\n";
    if (useColors) {
        std::cout << Colors::RESET;
    }
    std::cout << "\n";
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

    printResults(result);
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
