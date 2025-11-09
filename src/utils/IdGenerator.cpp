#include "../../include/utils/IdGenerator.h"
#include <chrono>
#include <iomanip>
#include <random>
#include <sstream>

std::string GeneratorUtil::generateCommitId() {
    auto now = std::chrono::system_clock::now();
    auto time = std::chrono::system_clock::to_time_t(now);

    std::tm utc = *std::gmtime(&time);

    std::ostringstream oss;
    oss << std::put_time(&utc, "%Y-%m-%dT%H-%M-%SZ");

    static std::mt19937 rng(std::random_device{}());
    static std::uniform_int_distribution<int> dist(0, 15);

    oss << "_";
    for (int i = 0; i < 6; ++i)
        oss << std::hex << dist(rng);

    return oss.str();
}
