#include "../../include/commands/CommitCommand.h"
#include <iostream>

std::string CommitCommand::getName() { return "commit"; }

bool CommitCommand::checkArgs(const std::vector<std::string> &args) {
    if (args.size() != 3 || args[2] != "-m")
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
}
