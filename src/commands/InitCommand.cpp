#include "../../include/commands/InitCommand.h"
#include "../../include/core/CommandRegistry.h"
#include "../../include/utils/utils.h"
#include <iostream>
#include <string>
#include <vector>

std::string InitCommand::getName() { return "init"; }

bool InitCommand::checkArgs(const std::vector<std::string> &args) {
    if (args.size() > 1)
        return false;

    return true;
}

void InitCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        std::cout << "Usage: minigit init\n";
        return;
    }

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

namespace {
struct InitCommandRegistrar {
    InitCommandRegistrar() {
        CommandRegistry::getInstance().registerCommand(
            "init", std::make_unique<InitCommand>());
    }
};

static InitCommandRegistrar registrar;
} // namespace
