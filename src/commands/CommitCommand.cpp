#include "../../include/commands/CommitCommand.h"
#include "../../include/utils/GeneratorUtils.h"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
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

void CommitCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        std::cout << "Usage: minigit commit -m <message>\n";
        return;
    }

    if (!Utils::exists(".minigit") || !Utils::exists(".minigit/index")) {
        std::cout << "Repository not initialized correctly\n";
    }

    std::string commitId = GeneratorUtils::generateCommitId();
    std::string commitMessage = getCommitMessage(args);

    fs::path src = fs::path(".minigit/index");
    fs::path commitPath =
        fs::path(".minigit/commits/" + commitId + "/snapshot");

    if (fs::is_empty(src)) {
        std::cout
            << "You cannot commit an empty index directory, make sure you have "
               "added files to the staging directory with:\n./build/minigit "
               "add "
               "<options>\n";

        return;
    }

    Utils::ensureDir(commitPath);
    Utils::copyDirRecursive(src, commitPath, false);
    Utils::removeDir(src);
    fs::create_directories(src);

    // Write info
    std::ofstream info(".minigit/commits/" + commitId + "/info");
    if (info.is_open()) {
        info << "Commit ID: " << commitId << "\n";
        info << "Message: "
             << (args.size() > 1 ? commitMessage : "(no message)") << "\n";

        info << "Author: " << std::getenv("USER") << "\n";
        info << "Date: " << GeneratorUtils::getCurrentTimeUTC() << "\n";

        info << "Files committed:\n";
        for (const auto &entry : fs::recursive_directory_iterator(commitPath)) {
            if (fs::is_regular_file(entry))
                info << "  - "
                     << fs::relative(entry.path(), commitPath).string() << "\n";
        }
    }

    std::cout << "Commit pushed to commits directory with id: " << commitId
              << '\n';
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
