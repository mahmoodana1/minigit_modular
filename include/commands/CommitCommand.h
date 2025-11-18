#pragma once
#include "../core/CommandRegistry.h"
#include "Command.h"
#include <string>
#include <vector>

class CommitCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    void description() override;
    std::string getName() override;

  protected:
    void commit(const std::string commitId, const std::string branchName,
                const std::string &commitMessage);
    void headMove(std::string branchName, std::string commitId);
    void pushToFilesTree(const std::string &branchName);
    void logCommit(const std::string &commitMessage,
                   const std::string &commitId, const std::string &branchName);
};
