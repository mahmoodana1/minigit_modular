#pragma once
#include <filesystem>
#include <string>
#include <vector>

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
bool fileNameExists(const fs::path &path, std::string name);
void printFilesInDirectory(const fs::path &path, bool branches = false);
std::vector<std::string> readLines(const fs::path &path);

} // namespace Utils
