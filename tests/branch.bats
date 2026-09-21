#!/bin/bash

MINIGIT="$BATS_TEST_DIRNAME/../build/minigit"

setup() {
  cd /tmp
  rm -rf minigit-tests && mkdir minigit-tests && cd minigit-tests
  "$MINIGIT" init >/dev/null
  echo "base" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  "$MINIGIT" commit -m "base" >/dev/null
}

# branch new
@test "branch new: creates head file" {
  "$MINIGIT" branch new dev >/dev/null
  [ -f ".minigit/heads/dev" ]
}

@test "branch new: prints success message" {
  run "$MINIGIT" branch new dev
  [[ "$output" == *"Branch 'dev' created successfully"* ]]
}

@test "branch new: head matches current branch head" {
  main_head=$(cat .minigit/heads/main)
  "$MINIGIT" branch new dev >/dev/null
  [ "$(cat .minigit/heads/dev)" = "$main_head" ]
}

@test "branch new: creates branchesFilesTree for the branch" {
  "$MINIGIT" branch new dev >/dev/null
  [ -d ".minigit/branchesFilesTree/dev" ]
}

@test "branch new: creates logs entry for the branch" {
  "$MINIGIT" branch new dev >/dev/null
  [ -f ".minigit/logs/heads/dev" ]
}

@test "branch new: does not switch to the new branch" {
  "$MINIGIT" branch new dev >/dev/null
  [ "$(cat .minigit/currentBranch)" = "main" ]
}

@test "branch new: multiple branches can be created" {
  "$MINIGIT" branch new dev >/dev/null
  "$MINIGIT" branch new feature >/dev/null
  [ -f ".minigit/heads/dev" ]
  [ -f ".minigit/heads/feature" ]
}

@test "branch new: branch made from another branch inherits that branch head" {
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null

  echo "devwork" >dev.txt
  "$MINIGIT" add dev.txt >/dev/null
  "$MINIGIT" commit -m "dev commit" >/dev/null
  dev_head=$(cat .minigit/heads/dev)

  "$MINIGIT" branch new feature >/dev/null
  [ "$(cat .minigit/heads/feature)" = "$dev_head" ]
  [ "$(cat .minigit/heads/feature)" != "$(cat .minigit/heads/main)" ]
}

@test "branch new: duplicate name prints already exists" {
  "$MINIGIT" branch new dev >/dev/null
  run "$MINIGIT" branch new dev
  [[ "$output" == *"already exists"* ]]
}

@test "branch new: duplicate does not change existing head" {
  "$MINIGIT" branch new dev >/dev/null
  before=$(cat .minigit/heads/dev)
  "$MINIGIT" branch new dev >/dev/null
  [ "$(cat .minigit/heads/dev)" = "$before" ]
}

@test "branch new: without name prints missing branch name" {
  run "$MINIGIT" branch new
  [[ "$output" == *"Missing branch name"* ]]
}

# branch delete
@test "branch delete: removes the head file" {
  "$MINIGIT" branch new dev >/dev/null
  "$MINIGIT" branch delete dev >/dev/null
  [ ! -e ".minigit/heads/dev" ]
}

@test "branch delete: prints success message" {
  "$MINIGIT" branch new dev >/dev/null
  run "$MINIGIT" branch delete dev
  [[ "$output" == *"Branch 'dev' deleted successfully"* ]]
}

@test "branch delete: does not change currentBranch" {
  "$MINIGIT" branch new dev >/dev/null
  "$MINIGIT" branch delete dev >/dev/null
  [ "$(cat .minigit/currentBranch)" = "main" ]
}

@test "branch delete: only removes the named branch" {
  "$MINIGIT" branch new dev >/dev/null
  "$MINIGIT" branch new feature >/dev/null
  "$MINIGIT" branch delete dev >/dev/null
  [ ! -e ".minigit/heads/dev" ]
  [ -f ".minigit/heads/feature" ]
  [ -f ".minigit/heads/main" ]
}

@test "branch delete: nonexistent branch prints not found" {
  run "$MINIGIT" branch delete ghost
  [[ "$output" == *"Branch not found"* ]]
}

@test "branch delete: cannot delete main" {
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  run "$MINIGIT" branch delete main
  [[ "$output" == *"cannot delete the 'main' branch"* ]]
  [ -f ".minigit/heads/main" ]
}

@test "branch delete: cannot delete the branch you are on" {
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  run "$MINIGIT" branch delete dev
  [[ "$output" == *"Cannot delete the branch you are currently on"* ]]
  [ -f ".minigit/heads/dev" ]
}

@test "branch delete: keeps current branch files tree" {
  "$MINIGIT" branch new dev >/dev/null
  "$MINIGIT" branch delete dev >/dev/null
  [ -f ".minigit/branchesFilesTree/main/base.txt" ]
}

@test "branch delete: without name prints missing branch name" {
  run "$MINIGIT" branch delete
  [[ "$output" == *"Missing branch name"* ]]
}

# branch list
@test "branch list: shows main" {
  run "$MINIGIT" branch list all
  [[ "$output" == *"main"* ]]
}

@test "branch list: shows newly created branch" {
  "$MINIGIT" branch new dev >/dev/null
  run "$MINIGIT" branch list all
  [[ "$output" == *"dev"* ]]
}

@test "branch list: shows multiple branches" {
  "$MINIGIT" branch new dev >/dev/null
  "$MINIGIT" branch new feature >/dev/null
  run "$MINIGIT" branch list all
  [[ "$output" == *"dev"* ]]
  [[ "$output" == *"feature"* ]]
  [[ "$output" == *"main"* ]]
}

@test "branch list: marks current branch" {
  run "$MINIGIT" branch list all
  [[ "$output" == *"*main"* ]]
}

@test "branch list: mark follows the current branch after switching" {
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  run "$MINIGIT" branch list all
  [[ "$output" == *"*dev"* ]]
}

@test "branch list: deleted branch no longer listed" {
  "$MINIGIT" branch new dev >/dev/null
  "$MINIGIT" branch delete dev >/dev/null
  run "$MINIGIT" branch list all
  [[ "$output" != *"dev"* ]]
}

@test "branch list: without all prints invalid usage" {
  run "$MINIGIT" branch list
  [[ "$output" == *"Invalid usage of 'list'"* ]]
}

# branch switch
@test "branch switch: updates currentBranch" {
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  [ "$(cat .minigit/currentBranch)" = "dev" ]
}

@test "branch switch: prints active branch" {
  "$MINIGIT" branch new dev >/dev/null
  run bash -c "echo y | '$MINIGIT' branch switch dev"
  [[ "$output" == *"Active Branch: dev"* ]]
}

@test "branch switch: nonexistent branch prints not found" {
  run "$MINIGIT" branch switch ghost
  [[ "$output" == *"not found"* ]]
}

@test "branch switch: cancelled with n keeps currentBranch" {
  "$MINIGIT" branch new dev >/dev/null
  echo n | "$MINIGIT" branch switch dev >/dev/null
  [ "$(cat .minigit/currentBranch)" = "main" ]
}

@test "branch switch: back and forth updates currentBranch each time" {
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  [ "$(cat .minigit/currentBranch)" = "dev" ]
  echo y | "$MINIGIT" branch switch main >/dev/null
  [ "$(cat .minigit/currentBranch)" = "main" ]
}

# branches with commits
@test "branch: deleting a branch keeps its commits" {
  m1=$(cat .minigit/heads/main)

  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "dev" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  d1=$("$MINIGIT" commit -m "d1" | awk '{print $NF}')

  echo y | "$MINIGIT" branch switch main >/dev/null
  "$MINIGIT" branch delete dev >/dev/null

  [ ! -e ".minigit/heads/dev" ]
  [ -d ".minigit/commits/$d1" ]
  [ "$(cat .minigit/commits/$d1/snapshot/d.txt)" = "dev" ]
  [ "$(cat .minigit/heads/main)" = "$m1" ]
}

@test "branch: each branch keeps its own commit ancestry" {
  m1=$(cat .minigit/heads/main)

  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "dev" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  d1=$("$MINIGIT" commit -m "d1" | awk '{print $NF}')

  echo y | "$MINIGIT" branch switch main >/dev/null
  echo "2" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  m2=$("$MINIGIT" commit -m "m2" | awk '{print $NF}')

  grep "Previous Commit ID: $m1" ".minigit/commits/$d1/refs"
  grep "Previous Commit ID: $m1" ".minigit/commits/$m2/refs"
}

@test "branch: heads move independently across switch cycles" {
  m1=$(cat .minigit/heads/main)

  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "dev" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  d1=$("$MINIGIT" commit -m "d1" | awk '{print $NF}')

  echo y | "$MINIGIT" branch switch main >/dev/null
  echo "2" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  m2=$("$MINIGIT" commit -m "m2" | awk '{print $NF}')

  [ "$(cat .minigit/heads/main)" = "$m2" ]
  [ "$(cat .minigit/heads/dev)" = "$d1" ]
  [ -d ".minigit/commits/$m1" ]
  [ -d ".minigit/commits/$d1" ]
  [ -d ".minigit/commits/$m2" ]
}

@test "branch: deleting a branch does not move other heads" {
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "dev" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null

  echo y | "$MINIGIT" branch switch main >/dev/null
  echo "2" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  m2=$("$MINIGIT" commit -m "m2" | awk '{print $NF}')

  "$MINIGIT" branch delete dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$m2" ]
}

@test "branch: recreated branch name starts from current head" {
  "$MINIGIT" branch new dev >/dev/null
  "$MINIGIT" branch delete dev >/dev/null

  echo "2" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  m2=$("$MINIGIT" commit -m "m2" | awk '{print $NF}')

  "$MINIGIT" branch new dev >/dev/null
  [ "$(cat .minigit/heads/dev)" = "$m2" ]
}

# error handling
@test "branch: no option prints usage" {
  run "$MINIGIT" branch
  [[ "$output" == *"Usage: minigit branch"* ]]
}

@test "branch: unknown option prints unknown option" {
  run "$MINIGIT" branch foo
  [[ "$output" == *"Unknown branch option: foo"* ]]
}

@test "branch: fails cleanly when .minigit missing" {
  rm -rf .minigit
  run "$MINIGIT" branch list all
  [[ "$output" == *"Repository not initialized correctly"* ]]
}
