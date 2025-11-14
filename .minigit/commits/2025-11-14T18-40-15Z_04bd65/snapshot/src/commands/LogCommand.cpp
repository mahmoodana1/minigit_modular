#include "../../include/commands/LogCommand.h"
#include <algorithm>
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

std::string LogCommand::getName() { return "log"; }

bool LogCommand::checkArgs(const std::vector<std::string> &args) {
    return (args.size() <= 2);
}

void LogCommand::description() {
    std::cout << R"(
Usage: minigit log [option]

Description:
  Shows commit history.

Options:
  (no option)     Show commit history for the current branch only.
  all             Show commit history from all branches.

Examples:
  minigit log
  minigit log all

Details:
  - By default, logs are shown for the active branch (based on .minigit/currentBranch).
  - 'log all' walks through every branch under .minigit/heads and prints every commit found.
  - Each commit displays: ID, message, author, date, and files.
)";
}

void LogCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        description();
        return;
    }

    // parse the logs
    fs::path currentBranchPath = fs::path(".minigit/currentBranch");
    std::string currentBranchName = Utils::getLine(currentBranchPath);
    std::string line;

    if (args.size() == 2 && args[1] == "all") {
        std::vector<std::string> parts =
            Utils::readLines(fs::path(".minigit/logs/commits_refs"));
        if (parts.empty()) {
            std::cout << "Couldn't find log history.\n";
            return;
        } else {
            printLogs(parts, false);
        }
    } else if (args.size() == 1) {
        std::vector<std::string> parts = Utils::readLines(
            fs::path(".minigit/logs/heads/" + currentBranchName));
        if (parts.empty()) {
            std::cout << "Couldn't find log history.\n";
        } else {
            printLogs(parts, true);
        }
    } else {
        description();
    }

    return;
}

void LogCommand::printLogs(const std::vector<std::string> &parts,
                           bool printBranch) {
    if (parts.empty())
        return;

    std::vector<std::pair<std::string, std::string>> commits;

    if (printBranch) {
        // input format: parent child parent child
        for (int i = 0; i + 1 < parts.size(); i += 2) {
            std::string child = parts[i + 1];

            if (!commits.empty() && commits.back().first == child)
                continue;

            commits.push_back({child, ""});
        }
    } else {
        // input format: parent child branch parent child branch
        for (int i = 0; i + 2 < parts.size(); i += 3) {
            std::string child = parts[i + 1];
            std::string branch = parts[i + 2];

            if (!commits.empty() && commits.back().first == child)
                continue;

            commits.push_back({child, branch});
        }
    }

    std::reverse(commits.begin(), commits.end());
    for (auto &entry : commits) {
        const std::string &id = entry.first;
        const std::string &branch = entry.second;

        std::string shortID = id.size() >= 7 ? id.substr(id.size() - 7) : id;

        if (printBranch)
            std::cout << "* " << shortID << "\n";
        else
            std::cout << "* " << shortID << " (" << branch << ")" << "\n";

        std::cout << "|\n";
    }

    std::cout << "*\n";
    return;
}

namespace {
struct LogCommandRegisterar {
    LogCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "log", std::make_unique<LogCommand>());
    }
};
static LogCommandRegisterar registerar;
} // namespace
