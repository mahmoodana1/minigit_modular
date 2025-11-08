#include "InitCommand.h"
#include "../utils/utils.h"
#include <iostream>
#include <vector>

bool checkArgs(const std::vector<std::string> &args) {
    if (args.size() > 1) {
        std::cout << "Usage: minigit init\n";
        return false;
    }
    return true;
}

void InitCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args))
        return;

    if (Utils::exists(".minigit")) {
        std::cout << "Repository already initialized.\n";
        return;
    }

    Utils::ensureDir(".minigit");
    Utils::ensureDir(".minigit/index");
    Utils::ensureDir(".minigit/commits");
    Utils::ensureDir(".minigit/logs");

    std::cout << "Initialized empty MiniGit repository.\n";
}
