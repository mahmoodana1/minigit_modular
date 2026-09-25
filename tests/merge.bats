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

diverge() {
  echo "base plus more" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  commit_on_dev
}

# merge arguments
@test "merge: no branch name prints usage" {
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

@test "merge: deleted branch prints select a valid branch" {
  "$MINIGIT" branch delete dev >/dev/null
  run "$MINIGIT" merge dev
  [[ "$output" == *"Select a valid Branch name"* ]]
}

# branches already in sync
@test "merge: same head prints in sync" {
  run "$MINIGIT" merge dev
  [[ "$output" == *"Branches are in sync"* ]]
}

@test "merge: in sync leaves both heads unchanged" {
  before=$(cat .minigit/heads/main)
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$before" ]
  [ "$(cat .minigit/heads/dev)" = "$before" ]
}

# fast-forward merge: files
@test "merge fast-forward: prints success message" {
  commit_on_dev
  run "$MINIGIT" merge dev
  [[ "$output" == *"Fast-forward merged into main"* ]]
}

@test "merge fast-forward: brings dev file into working tree" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ -f dev.txt ]
  [ "$(cat dev.txt)" = "dev" ]
}

@test "merge fast-forward: keeps main files" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ -f base.txt ]
}

@test "merge fast-forward: keeps new files from both branches" {
  echo "m" >m.txt
  "$MINIGIT" add m.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ -f m.txt ]
  [ -f dev.txt ]
}

@test "merge fast-forward: does not overwrite main's change" {
  echo "BASE" >base.txt
  "$MINIGIT" add base.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat base.txt)" = "BASE" ]
}

@test "merge fast-forward: does not leak untracked files into dev" {
  commit_on_dev
  echo "u" >untracked.txt
  "$MINIGIT" merge dev >/dev/null
  [ ! -e ".minigit/branchesFilesTree/dev/untracked.txt" ]
}

@test "merge fast-forward: status is clean afterwards" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  run env TERM=dumb "$MINIGIT" status
  echo "$output" | grep "dev.txt" | grep -q "clean"
  echo "$output" | grep "base.txt" | grep -q "clean"
}

# fast-forward merge: head movement
@test "merge fast-forward: moves main head to dev head" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$(cat .minigit/heads/dev)" ]
}

@test "merge fast-forward: keeps dev head unchanged" {
  commit_on_dev
  before=$(cat .minigit/heads/dev)
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/dev)" = "$before" ]
}

@test "merge fast-forward: main log shows dev commit" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"d1"* ]]
}

@test "merge fast-forward: several dev commits all land on main" {
  echo y | "$MINIGIT" branch switch dev >/dev/null
  for i in 1 2 3; do
    echo "$i" >"d$i.txt"
    "$MINIGIT" add "d$i.txt" >/dev/null
    "$MINIGIT" commit -m "d$i" >/dev/null
  done
  dev_head=$(cat .minigit/heads/dev)
  echo y | "$MINIGIT" branch switch main >/dev/null
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$dev_head" ]
  run "$MINIGIT" log
  [[ "$output" == *"d3"*"d2"*"d1"* ]]
}

@test "merge fast-forward: keeps main's own commit in log" {
  echo "m" >m.txt
  "$MINIGIT" add m.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"m2"* ]]
}

@test "merge fast-forward: next commit points to dev head" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  dev_head=$(cat .minigit/heads/dev)
  echo "after" >after.txt
  "$MINIGIT" add after.txt >/dev/null
  id=$("$MINIGIT" commit -m "after" | awk '{print $NF}')
  grep "Previous Commit ID: $dev_head" ".minigit/commits/$id/refs"
}

@test "merge fast-forward: merging back the other way is in sync" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  run "$MINIGIT" merge main
  [[ "$output" == *"Branches are in sync"* ]]
}

@test "merge fast-forward: merging an older branch does not move main head back" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  echo "n" >n.txt
  "$MINIGIT" add n.txt >/dev/null
  "$MINIGIT" commit -m "m3" >/dev/null
  before=$(cat .minigit/heads/main)
  "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$before" ]
}

# fast-forward merge: deletions
@test "merge fast-forward: file deleted on dev is deleted on main" {
  echo y | "$MINIGIT" branch switch dev >/dev/null
  rm base.txt
  echo "dev" >dev.txt
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  echo y | "$MINIGIT" branch switch main >/dev/null
  "$MINIGIT" merge dev >/dev/null
  [ ! -e base.txt ]
}

@test "merge fast-forward: file deleted on dev stays deleted on dev" {
  echo y | "$MINIGIT" branch switch dev >/dev/null
  rm base.txt
  echo "dev" >dev.txt
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  echo y | "$MINIGIT" branch switch main >/dev/null
  "$MINIGIT" merge dev >/dev/null
  [ ! -e ".minigit/branchesFilesTree/dev/base.txt" ]
}

@test "merge fast-forward: file deleted on main stays deleted" {
  rm base.txt
  echo "m" >m.txt
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  [ ! -e base.txt ]
}

@test "merge fast-forward: main head unchanged after deleting merged branch" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  before=$(cat .minigit/heads/main)
  "$MINIGIT" branch delete dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$before" ]
}

@test "merge fast-forward: merged files survive deleting merged branch" {
  commit_on_dev
  "$MINIGIT" merge dev >/dev/null
  "$MINIGIT" branch delete dev >/dev/null
  [ -f ".minigit/branchesFilesTree/main/dev.txt" ]
}

# diverged branches: prompt
@test "merge: diverged branches print cannot fast-forward" {
  diverge
  run bash -c "echo e | '$MINIGIT' merge dev"
  [[ "$output" == *"You cannot do Fast-forward merge"* ]]
}

@test "merge: answering e exits and leaves head unchanged" {
  diverge
  before=$(cat .minigit/heads/main)
  run bash -c "echo e | '$MINIGIT' merge dev"
  [[ "$output" == *"Exited merge"* ]]
  [ "$(cat .minigit/heads/main)" = "$before" ]
}

@test "merge: invalid answer prints invalid input" {
  diverge
  run bash -c "echo x | '$MINIGIT' merge dev"
  [[ "$output" == *"Invalid input"* ]]
}

# diverged branches: choosing files
@test "merge choose: conflict prompt names the file" {
  diverge
  run bash -c "printf 'y\nb\nmerged\n' | '$MINIGIT' merge dev"
  [[ "$output" == *"Conflict fount in file: base.txt"* ]]
}

@test "merge choose: picking a keeps main version in merge commit" {
  diverge
  printf "y\na\nmerged\n" | "$MINIGIT" merge dev >/dev/null
  id=$(cat .minigit/heads/main)
  [ "$(cat .minigit/commits/$id/snapshot/base.txt)" = "base plus more" ]
}

@test "merge choose: picking b keeps dev version in merge commit" {
  diverge
  printf "y\nb\nmerged\n" | "$MINIGIT" merge dev >/dev/null
  id=$(cat .minigit/heads/main)
  [ "$(cat .minigit/commits/$id/snapshot/base.txt)" = "base" ]
}

@test "merge choose: working tree gets the picked version" {
  diverge
  printf "y\nb\nmerged\n" | "$MINIGIT" merge dev >/dev/null
  [ "$(cat base.txt)" = "base" ]
}

@test "merge choose: working tree gets dev's new file" {
  diverge
  printf "y\nb\nmerged\n" | "$MINIGIT" merge dev >/dev/null
  [ -f dev.txt ]
}

# diverged branches: head movement
@test "merge choose: main head moves to the merge commit" {
  diverge
  before=$(cat .minigit/heads/main)
  printf "y\nb\nmerged\n" | "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/main)" != "$before" ]
}

@test "merge choose: main log shows the merge message" {
  diverge
  printf "y\nb\nmerged\n" | "$MINIGIT" merge dev >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"merged"* ]]
}

@test "merge choose: merge commit parent is main's old head" {
  diverge
  before=$(cat .minigit/heads/main)
  printf "y\nb\nmerged\n" | "$MINIGIT" merge dev >/dev/null
  id=$(cat .minigit/heads/main)
  grep "Previous Commit ID: $before" ".minigit/commits/$id/refs"
}

@test "merge choose: dev head does not move" {
  diverge
  before=$(cat .minigit/heads/dev)
  printf "y\nb\nmerged\n" | "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/dev)" = "$before" ]
}

@test "merge choose: exiting at the file prompt leaves head unchanged" {
  diverge
  before=$(cat .minigit/heads/main)
  printf "y\ne\n" | "$MINIGIT" merge dev >/dev/null
  [ "$(cat .minigit/heads/main)" = "$before" ]
}
