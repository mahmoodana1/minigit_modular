#pragma once
#include "Command.h"
#include <memory>
#include <vector>

class InitCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    std::string getName() override;
};
