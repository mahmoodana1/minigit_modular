#!/bin/bash

MINIGIT="$BATS_TEST_DIRNAME/../build/minigit"

setup() {
  cd /tmp
  rm -rf minigit-tests && mkdir minigit-tests && cd minigit-tests
  "$MINIGIT" init >/dev/null
}

@test "creates .minigit directory" {
  [ -d ".minigit" ]
}

@test "creates .minigit/index directory" {
  [ -d ".minigit/index" ]
}

@test "creates .minigit/commits directory" {
  [ -d ".minigit/commits" ]
}

@test "creates .minigit/logs directory" {
  [ -d ".minigit/logs" ]
}

@test "creates .minigit/heads directory" {
  [ -d ".minigit/heads" ]
}

@test "creates .minigit/branchesFilesTree/main directory" {
  [ -d ".minigit/branchesFilesTree/main" ]
}

@test "creates .minigit/tmp directory" {
  [ -d ".minigit/tmp" ]
}

@test "creates .minigit/currentBranch file" {
  [ -f ".minigit/currentBranch" ]
}

@test ".minigit/currentBranch contains 'main'" {
  [ "$(cat .minigit/currentBranch)" = "main" ]
}

@test "creates .minigit/heads/main file" {
  [ -f ".minigit/heads/main" ]
}

@test ".minigit/heads/main contains 'none'" {
  [ "$(cat .minigit/heads/main)" = "none" ]
}
