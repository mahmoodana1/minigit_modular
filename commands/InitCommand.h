#pragma once
#include "Command.h"

class InitCommand : Command {
    void execute(const std::vector<std::string> &args);
    std::string getName();
};
