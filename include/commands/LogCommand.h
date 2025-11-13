#pragma once
#include "../core/CommandRegistry.h"
#include "Command.h"

class LogCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    void description() override;
    std::string getName() override;
};
