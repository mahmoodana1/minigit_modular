#include "CommandRegistry.h"
#include <iostream>
#include <memory>
#include <utility>

CommandRegistry &CommandRegistry::getInstance() {
    static CommandRegistry instance = CommandRegistry();
    return instance;
}

void CommandRegistry::registerCommand(const std::string &name,
                                      std::unique_ptr<Command> command) {
    if (commands.find(name) != commands.end()) {
        std::cout << "Command already exists\n";
        return;
    }

    commands[name] = std::move(command);
}

Command *CommandRegistry::getCommand(const std::string &name) {
    auto it = commands.find(name);
    if (it != commands.end()) {
        return it->second.get();
    }

    return nullptr;
}
