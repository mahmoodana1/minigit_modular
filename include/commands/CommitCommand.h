#pragma once
#include "../core/CommandRegistry.h"
#include "Command.h"

class CommitCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    std::string getName() override;
    void headMove(std::string branchName, std::string commitId);
};
