#include "../../include/commands/AddCommand.h"
#include "../../include/core/CommandRegistry.h"
#include <iostream>
#include <string>
#include <sys/types.h>

std::string AddCommand::getName() { return "init"; }

bool AddCommand::checkArgs(const std::vector<std::string> &args) {
    if (args.size() != 2)
        return false;

    return true;
}

void AddCommand::execute(const std::vector<std::string> &args) {
    if (!checkArgs(args)) {
        std::cout << "Usage: minigit add <option>\n";
        return;
    }

    if (!Utils::exists(".minigit") || !Utils::exists(".minigit/index")) {
        std::cout << "Repository not initialized correctly\n";
    }

    if (args[1] == ".") {
        Utils::copyDirRecursive(".", "./.minigit/index");
        return;
    }

    if (!Utils::exists(args[1])) {
        std::cout << "source file not found\n";
        return;
    }

    Utils::copyFileSafe(args[1], "./.minigit/index");
}

namespace {
struct AddCommandRegisterar {
    AddCommandRegisterar() {
        CommandRegistry::getInstance().registerCommand(
            "add", std::make_unique<AddCommand>());
    }
};
static AddCommandRegisterar registerar;
} // namespace
