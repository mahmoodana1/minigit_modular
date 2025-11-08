#include "InitCommand.h"
#include "../utils/utils.h"
#include <iostream>

void InitCommand::execute(const std::vector<std::string> &args) {
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
