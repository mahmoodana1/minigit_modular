#pragma once
#include <filesystem>
#include <string>

namespace fs = std::filesystem;

namespace Utils {
void copyDirRecursive(const fs::path &src, const fs::path &dest,
                      bool skipMeta = true);
void copyFileSafe(const fs::path &src, const fs::path &dest);
void removeDir(const fs::path &path);
void ensureDir(const fs::path &path);
bool exists(const fs::path &path);
std::string getLine(const fs::path &path);
void clearAndPushLine(const fs::path &path, std::string line);

} // namespace Utils
