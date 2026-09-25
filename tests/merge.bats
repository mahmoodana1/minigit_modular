#!/bin/bash

MINIGIT="$BATS_TEST_DIRNAME/../build/minigit"

setup() {
  cd /tmp
  rm -rf minigit-tests && mkdir minigit-tests && cd minigit-tests
  "$MINIGIT" init >/dev/null
  echo "base" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  "$MINIGIT" commit -m "base" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
}

commit_on_dev() {
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "dev" >dev.txt
  "$MINIGIT" add dev.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  echo y | "$MINIGIT" branch switch main >/dev/null
}

# arguments
@test "merge: no branch prints usage" {
  run "$MINIGIT" merge
  [[ "$output" == *"Usage: minigit merge"* ]]
}

@test "merge: too many args prints usage" {
  run "$MINIGIT" merge dev extra
  [[ "$output" == *"Usage: minigit merge"* ]]
}

@test "merge: current branch prints select a valid branch" {
  run "$MINIGIT" merge main
  [[ "$output" == *"Select a valid Branch name"* ]]
}

@test "merge: nonexistent branch prints select a valid branch" {
  run "$MINIGIT" merge ghost
  [[ "$output" == *"Select a valid Branch name"* ]]
}

# in sync
@test "merge: same head prints in sync" {
  run "$MINIGIT" merge dev
  [[ "$output" == *"Branches are in sync"* ]]
}

@test "merge: in sync leaves heads unchanged" {
  before=$(cat .minigit/heads/main)
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$before" ]
  [ "$(cat .minigit/heads/dev)" = "$before" ]
}

# fast-forward
@test "merge: fast-forward prints message" {
  commit_on_dev
  run "$MINIGIT" merge dev
  [[ "$output" == *"Fast-forward merged into main"* ]]
}

@test "merge: fast-forward moves main head to dev head" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$(cat .minigit/heads/dev)" ]
}

@test "merge: fast-forward keeps dev head unchanged" {
  commit_on_dev
  before=$(cat .minigit/heads/dev)
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/dev)" = "$before" ]
}

@test "merge: fast-forward brings dev file into working tree" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ -f dev.txt ]
  [ "$(cat dev.txt)" = "dev" ]
}

@test "merge: fast-forward keeps main files" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ -f base.txt ]
}

@test "merge: fast-forward main log shows dev commit" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"d1"* ]]
}

# not fast-forward
@test "merge: diverged branches print cannot fast-forward" {
  echo "base plus more" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  run bash -c "echo e | '$MINIGIT' merge dev"
  [[ "$output" == *"You cannot do Fast-forward merge"* ]]
}

@test "merge: answering e exits and leaves head unchanged" {
  echo "base plus more" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  before=$(cat .minigit/heads/main)
  run bash -c "echo e | '$MINIGIT' merge dev"
  [[ "$output" == *"Exited merge"* ]]
  [ "$(cat .minigit/heads/main)" = "$before" ]
}

@test "merge: invalid answer prints invalid input" {
  echo "base plus more" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  run bash -c "echo x | '$MINIGIT' merge dev"
  [[ "$output" == *"Invalid input"* ]]
}
