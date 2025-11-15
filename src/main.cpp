#include "../include/core/CommandRegistry.h"
#include <iostream>
#include <string>
#include <vector>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::cout << "Usage: minigit <command> [args...]\n";
        return 1;
    }

    std::string commandName = argv[1];

    std::vector<std::string> args(argv + 1, argv + argc);

    CommandRegistry &commandRegistry = CommandRegistry::getInstance();

    if (commandRegistry.getCommand(commandName) == nullptr) {
        std::cout << "Unknown command: " << commandName << "\n"
                  << "Usage: minigit <command> [args...]\n";
        std::cout << "Commands: \n"
                  << "'init'\n'add'\n'commit'\n'branch'\n'log'\n'status'\n";
        return 1;
    }

    commandRegistry.getCommand(commandName)->execute(args);
    return 0;
}
