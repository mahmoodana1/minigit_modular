#pragma once
#include "Command.h"
#include <vector>

class InitCommand : Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    std::string getName() const { return "init"; }
};
