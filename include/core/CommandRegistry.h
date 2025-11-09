#pragma once
#include "../commands/Command.h"
#include <memory>
#include <string>
#include <unordered_map>

class CommandRegistry {
  public:
    static CommandRegistry &getInstance();
    void registerCommand(const std::string &name,
                         std::unique_ptr<Command> command);
    Command *getCommand(const std::string &name);

  private:
    std::unordered_map<std::string, std::unique_ptr<Command>> commands;
    CommandRegistry() = default;
    CommandRegistry(const CommandRegistry &) = delete;
    CommandRegistry &operator=(const CommandRegistry &) = delete;
};
