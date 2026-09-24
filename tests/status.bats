#!/bin/bash

MINIGIT="$BATS_TEST_DIRNAME/../build/minigit"

setup() {
  cd /tmp
  rm -rf minigit-tests && mkdir minigit-tests && cd minigit-tests
  "$MINIGIT" init >/dev/null
  export TERM=dumb
}

commit_base() {
  echo "base" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  "$MINIGIT" commit -m "base" >/dev/null
}

# before any commit
@test "status: no commits asks for a commit first" {
  run "$MINIGIT" status
  [[ "$output" == *"Please make a commit before checking the status"* ]]
}

# file states
@test "status: committed file shows clean" {
  commit_base
  run "$MINIGIT" status
  echo "$output" | grep "base.txt" | grep -q "clean"
}

@test "status: new file shows untracked" {
  commit_base
  echo "new" >new.txt
  run "$MINIGIT" status
  echo "$output" | grep "new.txt" | grep -q "untracked"
}

@test "status: new file added shows new file staged" {
  commit_base
  echo "new" >new.txt
  "$MINIGIT" add new.txt >/dev/null
  run "$MINIGIT" status
  echo "$output" | grep "new.txt" | grep -q "new file staged"
}

@test "status: committed file changed shows modified" {
  commit_base
  echo "changed" >base.txt
  run "$MINIGIT" status
  echo "$output" | grep "base.txt" | grep -q "modified"
}

@test "status: committed file changed and added shows staged" {
  commit_base
  echo "changed" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  run "$MINIGIT" status
  echo "$output" | grep "base.txt" | grep -q "staged"
}

@test "status: committed file deleted shows deleted" {
  commit_base
  rm base.txt
  run "$MINIGIT" status
  echo "$output" | grep "base.txt" | grep -q "deleted"
}

@test "status: nested file shows with its path" {
  commit_base
  mkdir -p sub
  echo "x" >sub/nested.txt
  run "$MINIGIT" status
  echo "$output" | grep "sub/nested.txt" | grep -q "untracked"
}

# output
@test "status: prints table header" {
  commit_base
  run "$MINIGIT" status
  [[ "$output" == *"File Path"* ]]
  [[ "$output" == *"Status"* ]]
}

@test "status: does not list .minigit files" {
  commit_base
  run "$MINIGIT" status
  [[ "$output" != *".minigit"* ]]
}

# error handling
@test "status: extra args prints usage" {
  commit_base
  run "$MINIGIT" status foo
  [[ "$output" == *"Usage: minigit status"* ]]
}
