#include "../../include/commands/LogCommand.h"
#include <algorithm>
#include <filesystem>
#include <fstream>
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

    std::vector<std::tuple<std::string, std::string, std::string>> logs;

    // load logs from
    if (printBranch) {
        // parent child parent child
        for (size_t i = 0; i + 1 < parts.size(); i += 2) {
            std::string commitID = parts[i + 1];

            // read commit message from file
            std::string msgPath = ".minigit/commits/" + commitID + "/info";
            std::string msg = LogCommand::extractMessage(msgPath);

            logs.push_back({commitID, "", msg});
        }
    } else {
        // parent child branch
        for (size_t i = 0; i + 2 < parts.size(); i += 3) {
            std::string commitID = parts[i + 1];
            std::string branchName = parts[i + 2];

            std::string msgPath = ".minigit/commits/" + commitID + "/info";
            std::string msg = LogCommand::extractMessage(msgPath);

            logs.push_back({commitID, branchName, msg});
        }
    }

    // newest first
    std::reverse(logs.begin(), logs.end());

    for (size_t i = 0; i < logs.size(); i++) {
        auto &[id, branch, msg] = logs[i];
        std::string shortID = id.size() > 7 ? id.substr(0, 7) : id;

        std::cout << "* commit " << shortID;

        if (!branch.empty())
            std::cout << " (" << branch << ")";

        std::cout << "\n";

        std::cout << "|  Message: " << msg << "\n";

        if (i + 1 < logs.size())
            std::cout << "|\n";
    }

    std::cout << "*\n";
}

std::string LogCommand::extractMessage(const fs::path &infoPath) {
    std::ifstream file(infoPath);
    if (!file.is_open())
        return "";

    std::string line;
    std::string message;
    bool inMessage = false;

    while (std::getline(file, line)) {

        if (line.rfind("Message:", 0) == 0) {
            inMessage = true;
            if (line.size() > 8) {
                message += line.substr(8) + "\n";
            }
            continue;
        }

        if (line.rfind("Author:", 0) == 0) {
            break;
        }

        if (inMessage) {
            message += line + "\n";
        }
    }

    return message;
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
