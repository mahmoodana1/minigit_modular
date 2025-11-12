#pragma once
#include "../core/CommandRegistry.h"
#include "Command.h"

class BranchCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    std::string getName() override;
    void branchCommandsExecute(std::string commandd, std::string branchName);
};
