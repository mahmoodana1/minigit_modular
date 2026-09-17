#!/bin/bash

MINIGIT="$BATS_TEST_DIRNAME/../build/minigit"

setup() {
  cd /tmp
  rm -rf minigit-tests && mkdir minigit-tests && cd minigit-tests
  "$MINIGIT" init >/dev/null
}

# single file tests
@test "add: single file appears in index" {
  echo "hello" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  [ -f ".minigit/index/file.txt" ]
}

@test "add: single file content preserved" {
  echo "hello world" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  [ "$(cat .minigit/index/file.txt)" = "hello world" ]
}

@test "add: multi-line content preserved" {
  printf "line1\nline2\nline3\n" >multi.txt
  "$MINIGIT" add multi.txt >/dev/null
  diff multi.txt .minigit/index/multi.txt
}

@test "add: file with no trailing newline preserved" {
  printf "no-newline" >raw.txt
  "$MINIGIT" add raw.txt >/dev/null
  [ "$(wc -c <.minigit/index/raw.txt)" -eq 10 ]
}

@test "add: binary content preserved" {
  head -c 256 /dev/urandom >bin.dat
  "$MINIGIT" add bin.dat >/dev/null
  cmp bin.dat .minigit/index/bin.dat
}

@test "add: empty file indexed as empty" {
  : >empty.txt
  "$MINIGIT" add empty.txt >/dev/null
  [ -f ".minigit/index/empty.txt" ]
  [ ! -s ".minigit/index/empty.txt" ]
}

@test "add: filename with spaces preserved" {
  echo "spaced" >"my file.txt"
  "$MINIGIT" add "my file.txt" >/dev/null
  [ -f ".minigit/index/my file.txt" ]
}

@test "add: dotfile indexed" {
  echo "cfg" >.hiddenrc
  "$MINIGIT" add .hiddenrc >/dev/null
  [ -f ".minigit/index/.hiddenrc" ]
}

# nested paths
@test "add: nested file preserves relative path" {
  mkdir -p sub
  echo "x" >sub/nested.txt
  "$MINIGIT" add sub/nested.txt >/dev/null
  [ -f ".minigit/index/sub/nested.txt" ]
}

@test "add: deeply nested path preserved" {
  mkdir -p a/b/c/d
  echo "deep" >a/b/c/d/file.txt
  "$MINIGIT" add a/b/c/d/file.txt >/dev/null
  [ -f ".minigit/index/a/b/c/d/file.txt" ]
}

@test "add: leading ./ prefix works" {
  echo "ok" >file.txt
  "$MINIGIT" add ./file.txt >/dev/null
  [ -f ".minigit/index/file.txt" ]
}

# recursive add
@test "add .: top-level file copied" {
  echo "a" >a.txt
  "$MINIGIT" add . >/dev/null
  [ -f ".minigit/index/a.txt" ]
}

@test "add .: nested file copied" {
  mkdir -p sub
  echo "b" >sub/b.txt
  "$MINIGIT" add . >/dev/null
  [ -f ".minigit/index/sub/b.txt" ]
}

@test "add .: multiple top-level files copied" {
  echo "1" >a.txt
  echo "2" >b.txt
  echo "3" >c.txt
  "$MINIGIT" add . >/dev/null
  [ -f ".minigit/index/a.txt" ]
  [ -f ".minigit/index/b.txt" ]
  [ -f ".minigit/index/c.txt" ]
}

@test "add .: .minigit not recursed into index" {
  echo "a" >a.txt
  "$MINIGIT" add . >/dev/null
  [ ! -e ".minigit/index/.minigit" ]
}

@test "add .: .git directory skipped" {
  mkdir -p .git
  echo "internal" >.git/config
  echo "real" >real.txt
  "$MINIGIT" add . >/dev/null
  [ -f ".minigit/index/real.txt" ]
  [ ! -e ".minigit/index/.git" ]
}

@test "add .: content of copied files matches source" {
  echo "alpha" >a.txt
  mkdir -p d
  echo "beta" >d/b.txt
  "$MINIGIT" add . >/dev/null
  [ "$(cat .minigit/index/a.txt)" = "alpha" ]
  [ "$(cat .minigit/index/d/b.txt)" = "beta" ]
}

# overwriting
@test "add: re-adding modified file updates content" {
  echo "v1" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  echo "v2" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  [ "$(cat .minigit/index/file.txt)" = "v2" ]
}

@test "add: re-adding as empty truncates indexed copy" {
  echo "not empty" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  : >file.txt
  "$MINIGIT" add file.txt >/dev/null
  [ ! -s ".minigit/index/file.txt" ]
}

@test "add: sequential adds accumulate in index" {
  echo "1" >a.txt
  echo "2" >b.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" add b.txt >/dev/null
  [ -f ".minigit/index/a.txt" ]
  [ -f ".minigit/index/b.txt" ]
}

@test "add: one file does not disturb previously indexed file" {
  echo "keep" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  echo "new" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  [ "$(cat .minigit/index/a.txt)" = "keep" ]
}

@test "add: same file added twice produces same content" {
  echo "same" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  "$MINIGIT" add file.txt >/dev/null
  [ "$(cat .minigit/index/file.txt)" = "same" ]
}

# error handling
@test "add: no path arg prints usage" {
  run "$MINIGIT" add
  [[ "$output" == *"Usage: minigit add"* ]]
}

@test "add: too many args prints usage" {
  echo "x" >a.txt
  echo "y" >b.txt
  run "$MINIGIT" add a.txt b.txt
  [[ "$output" == *"Usage: minigit add"* ]]
}

@test "add: nonexistent file prints 'source file not found'" {
  run "$MINIGIT" add ghost.txt
  [[ "$output" == *"source file not found"* ]]
}

@test "add: nonexistent nested path prints 'source file not found'" {
  run "$MINIGIT" add sub/ghost.txt
  [[ "$output" == *"source file not found"* ]]
}

@test "add: fails cleanly when .minigit missing" {
  rm -rf .minigit
  echo "x" >file.txt
  run "$MINIGIT" add file.txt
  [[ "$output" == *"Repository not initialized correctly"* ]]
}

@test "add: fails cleanly when .minigit/index missing" {
  rm -rf .minigit/index
  echo "x" >file.txt
  run "$MINIGIT" add file.txt
  [[ "$output" == *"Repository not initialized correctly"* ]]
}

@test "add: directory arg does not index as a file" {
  mkdir -p somedir
  echo "inside" >somedir/f.txt
  "$MINIGIT" add somedir >/dev/null 2>&1 || true
  [ ! -f ".minigit/index/somedir" ]
}

# deletions
@test "add: deleted file arg prints 'source file not found'" {
  echo "gone" >file.txt
  rm file.txt
  run "$MINIGIT" add file.txt
  [[ "$output" == *"source file not found"* ]]
}

@test "add: indexed file survives after source is deleted" {
  echo "keeper" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  rm a.txt
  echo "new" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  [ -f ".minigit/index/a.txt" ]
  [ "$(cat .minigit/index/a.txt)" = "keeper" ]
}

@test "add .: deleting source file leaves stale index entry" {
  echo "x" >a.txt
  echo "y" >b.txt
  "$MINIGIT" add . >/dev/null
  rm a.txt
  "$MINIGIT" add . >/dev/null
  [ -f ".minigit/index/a.txt" ]
  [ -f ".minigit/index/b.txt" ]
}

@test "add .: does not crash when indexed file missing from tree" {
  echo "one" >a.txt
  "$MINIGIT" add . >/dev/null
  rm a.txt
  run "$MINIGIT" add .
  [ "$status" -eq 0 ]
}

# recursive deletions
@test "add .: removing a subdir does not break siblings" {
  mkdir -p keep gone
  echo "k1" >keep/k1.txt
  echo "g1" >gone/g1.txt
  "$MINIGIT" add . >/dev/null
  rm -rf gone
  echo "k2" >keep/k2.txt
  "$MINIGIT" add . >/dev/null
  [ -f ".minigit/index/keep/k1.txt" ]
  [ -f ".minigit/index/keep/k2.txt" ]
}

@test "add: file inside a deleted directory prints not-found" {
  mkdir -p sub
  echo "hi" >sub/nested.txt
  "$MINIGIT" add sub/nested.txt >/dev/null
  rm -rf sub
  run "$MINIGIT" add sub/nested.txt
  [[ "$output" == *"source file not found"* ]]
}

@test "add .: recreated file after deletion is re-indexed" {
  echo "v1" >file.txt
  "$MINIGIT" add . >/dev/null
  rm file.txt
  echo "v2" >file.txt
  "$MINIGIT" add . >/dev/null
  [ "$(cat .minigit/index/file.txt)" = "v2" ]
}

@test "add .: deleting nested tree then adding new tree works" {
  mkdir -p old/deep
  echo "o" >old/deep/x.txt
  "$MINIGIT" add . >/dev/null
  rm -rf old
  mkdir -p fresh/deep
  echo "f" >fresh/deep/y.txt
  "$MINIGIT" add . >/dev/null
  [ -f ".minigit/index/fresh/deep/y.txt" ]
  [ "$(cat .minigit/index/fresh/deep/y.txt)" = "f" ]
}

# similar named files
@test "add: foo.txt and foo.txt.bak index as distinct entries" {
  echo "main" >foo.txt
  echo "backup" >foo.txt.bak
  "$MINIGIT" add foo.txt >/dev/null
  "$MINIGIT" add foo.txt.bak >/dev/null
  [ "$(cat .minigit/index/foo.txt)" = "main" ]
  [ "$(cat .minigit/index/foo.txt.bak)" = "backup" ]
}

@test "add: adding foo.txt does not touch foo.txt.bak" {
  echo "main" >foo.txt
  echo "backup" >foo.txt.bak
  "$MINIGIT" add foo.txt >/dev/null
  [ ! -e ".minigit/index/foo.txt.bak" ]
}

@test "add: foo and foo.txt are distinct entries" {
  echo "no-ext" >foo
  echo "with-ext" >foo.txt
  "$MINIGIT" add foo >/dev/null
  "$MINIGIT" add foo.txt >/dev/null
  [ "$(cat .minigit/index/foo)" = "no-ext" ]
  [ "$(cat .minigit/index/foo.txt)" = "with-ext" ]
}

@test "add: same basename in different dirs indexed at both paths" {
  mkdir -p a b
  echo "in-a" >a/file.txt
  echo "in-b" >b/file.txt
  "$MINIGIT" add a/file.txt >/dev/null
  "$MINIGIT" add b/file.txt >/dev/null
  [ "$(cat .minigit/index/a/file.txt)" = "in-a" ]
  [ "$(cat .minigit/index/b/file.txt)" = "in-b" ]
}

@test "add: prefix-named files do not shadow each other" {
  echo "short" >note
  echo "longer" >notes
  echo "longest" >notes.md
  "$MINIGIT" add . >/dev/null
  [ "$(cat .minigit/index/note)" = "short" ]
  [ "$(cat .minigit/index/notes)" = "longer" ]
  [ "$(cat .minigit/index/notes.md)" = "longest" ]
}

@test "add: case-sensitive filenames indexed as distinct" {
  echo "upper" >README
  echo "lower" >readme
  "$MINIGIT" add . >/dev/null
  [ "$(cat .minigit/index/README)" = "upper" ]
  [ "$(cat .minigit/index/readme)" = "lower" ]
}

@test "add: file with dot suffix coexists with same-named directory" {
  mkdir -p src
  echo "code" >src/main.cpp
  echo "archive" >src.old
  "$MINIGIT" add . >/dev/null
  [ -f ".minigit/index/src/main.cpp" ]
  [ -f ".minigit/index/src.old" ]
  [ "$(cat .minigit/index/src.old)" = "archive" ]
}
