#include "../../include/commands/CommitCommand.h"
#include "../../include/utils/IdGenerator.h"
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

    std::string commitId = GeneratorUtil::generateCommitId();
    std::string commitMessage = getCommitMessage(args);
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
