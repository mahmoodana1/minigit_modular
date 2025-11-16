#pragma once
#include "../core/CommandRegistry.h"
#include "Command.h"
#include <filesystem>

class StatusCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    void description() override;
    void compareFiles();
    std::string getName() override;
};
