#!/bin/bash

MINIGIT="$BATS_TEST_DIRNAME/../build/minigit"

setup() {
  cd /tmp
  rm -rf minigit-tests && mkdir minigit-tests && cd minigit-tests
  "$MINIGIT" init >/dev/null
}

# empty files
@test "commit: two empty files both appear in snapshot as empty" {
  : >a.txt
  : >b.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "two empties" >/dev/null
  id=$(ls .minigit/commits)
  [ -f ".minigit/commits/$id/snapshot/a.txt" ]
  [ -f ".minigit/commits/$id/snapshot/b.txt" ]
  [ ! -s ".minigit/commits/$id/snapshot/a.txt" ]
  [ ! -s ".minigit/commits/$id/snapshot/b.txt" ]
}

@test "commit: same empty file added twice appears once in snapshot" {
  : >empty.txt
  "$MINIGIT" add empty.txt >/dev/null
  "$MINIGIT" add empty.txt >/dev/null
  "$MINIGIT" commit -m "dup empty" >/dev/null
  id=$(ls .minigit/commits)
  [ -f ".minigit/commits/$id/snapshot/empty.txt" ]
  [ ! -s ".minigit/commits/$id/snapshot/empty.txt" ]
}

@test "commit: empty file removed and recreated with content committed with new content" {
  : >file.txt
  "$MINIGIT" add file.txt >/dev/null
  "$MINIGIT" commit -m "first" >/dev/null
  rm file.txt
  echo "now with content" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  out=$("$MINIGIT" commit -m "second")
  id=$(echo "$out" | awk '{print $NF}')
  [ "$(cat .minigit/commits/$id/snapshot/file.txt)" = "now with content" ]
}

# directories
@test "commit: directory contents appear in snapshot" {
  mkdir -p dir
  echo "content" >dir/file.txt
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "dir" >/dev/null
  id=$(ls .minigit/commits)
  [ -f ".minigit/commits/$id/snapshot/dir/file.txt" ]
  [ "$(cat .minigit/commits/$id/snapshot/dir/file.txt)" = "content" ]
}

@test "commit: same directory added twice keeps contents identical in snapshot" {
  mkdir -p dir
  echo "content" >dir/file.txt
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "dup dir" >/dev/null
  id=$(ls .minigit/commits)
  [ "$(cat .minigit/commits/$id/snapshot/dir/file.txt)" = "content" ]
}

@test "commit: file in directory removed and recreated with different content committed as new" {
  mkdir -p dir
  echo "old" >dir/file.txt
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "first" >/dev/null
  rm dir/file.txt
  echo "new" >dir/file.txt
  "$MINIGIT" add . >/dev/null
  out=$("$MINIGIT" commit -m "second")
  id=$(echo "$out" | awk '{print $NF}')
  [ "$(cat .minigit/commits/$id/snapshot/dir/file.txt)" = "new" ]
}

# empty directories
@test "commit: empty directory appears in snapshot" {
  mkdir -p emptydir
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "empty dir" >/dev/null
  id=$(ls .minigit/commits)
  [ -d ".minigit/commits/$id/snapshot/emptydir" ]
}

@test "commit: two empty directories both appear in snapshot" {
  mkdir -p e1 e2
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "two empty dirs" >/dev/null
  id=$(ls .minigit/commits)
  [ -d ".minigit/commits/$id/snapshot/e1" ]
  [ -d ".minigit/commits/$id/snapshot/e2" ]
}

@test "commit: same empty directory added twice stays empty in snapshot" {
  mkdir -p emptydir
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "dup empty dir" >/dev/null
  id=$(ls .minigit/commits)
  [ -d ".minigit/commits/$id/snapshot/emptydir" ]
  [ -z "$(ls -A .minigit/commits/$id/snapshot/emptydir)" ]
}

@test "commit: empty directory removed and recreated with file committed with file" {
  mkdir -p dir
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "first" >/dev/null
  rm -rf dir
  mkdir -p dir
  echo "new" >dir/file.txt
  "$MINIGIT" add . >/dev/null
  out=$("$MINIGIT" commit -m "second")
  id=$(echo "$out" | awk '{print $NF}')
  [ -f ".minigit/commits/$id/snapshot/dir/file.txt" ]
  [ "$(cat .minigit/commits/$id/snapshot/dir/file.txt)" = "new" ]
}

# staging and deletion
@test "commit: file staged then deleted from working tree still appears in snapshot" {
  echo "content" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  rm file.txt
  id=$("$MINIGIT" commit -m "staged deleted" | awk '{print $NF}')
  [ -f ".minigit/commits/$id/snapshot/file.txt" ]
  [ "$(cat .minigit/commits/$id/snapshot/file.txt)" = "content" ]
}

@test "commit: working-tree modification without re-staging keeps staged version in snapshot" {
  echo "v1" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  echo "v2" >file.txt
  id=$("$MINIGIT" commit -m "unstaged modify" | awk '{print $NF}')
  [ "$(cat .minigit/commits/$id/snapshot/file.txt)" = "v1" ]
}

@test "commit: multiple staged files survive when some deleted from working tree" {
  echo "a" >a.txt
  echo "b" >b.txt
  echo "c" >c.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" add c.txt >/dev/null
  rm b.txt
  id=$("$MINIGIT" commit -m "some deleted" | awk '{print $NF}')
  [ "$(cat .minigit/commits/$id/snapshot/a.txt)" = "a" ]
  [ "$(cat .minigit/commits/$id/snapshot/b.txt)" = "b" ]
  [ "$(cat .minigit/commits/$id/snapshot/c.txt)" = "c" ]
}

@test "commit: nested file staged then parent directory deleted still appears in snapshot" {
  mkdir -p dir
  echo "content" >dir/file.txt
  "$MINIGIT" add dir/file.txt >/dev/null
  rm -rf dir
  id=$("$MINIGIT" commit -m "parent deleted" | awk '{print $NF}')
  [ -f ".minigit/commits/$id/snapshot/dir/file.txt" ]
  [ "$(cat .minigit/commits/$id/snapshot/dir/file.txt)" = "content" ]
}

@test "commit: staged file survives failed re-add after source deletion" {
  echo "orig" >file.txt
  "$MINIGIT" add file.txt >/dev/null
  rm file.txt
  "$MINIGIT" add file.txt >/dev/null 2>&1 || true
  id=$("$MINIGIT" commit -m "failed re-add" | awk '{print $NF}')
  [ "$(cat .minigit/commits/$id/snapshot/file.txt)" = "orig" ]
}

# commit metadata
@test "commit: info and refs files created" {
  echo "x" >f.txt
  "$MINIGIT" add f.txt >/dev/null
  id=$("$MINIGIT" commit -m "msg" | awk '{print $NF}')
  [ -f ".minigit/commits/$id/info" ]
  [ -f ".minigit/commits/$id/refs" ]
}

@test "commit: info contains the commit message" {
  echo "x" >f.txt
  "$MINIGIT" add f.txt >/dev/null
  id=$("$MINIGIT" commit -m "my message" | awk '{print $NF}')
  grep "Message: my message" ".minigit/commits/$id/info"
}

@test "commit: info message has no trailing space" {
  echo "x" >f.txt
  "$MINIGIT" add f.txt >/dev/null
  id=$("$MINIGIT" commit -m "my message" | awk '{print $NF}')
  grep -x "Message: my message" ".minigit/commits/$id/info"
}

@test "commit: info lists the committed file" {
  echo "x" >f.txt
  "$MINIGIT" add f.txt >/dev/null
  id=$("$MINIGIT" commit -m "msg" | awk '{print $NF}')
  grep "f.txt" ".minigit/commits/$id/info"
}

@test "commit: first commit refs shows none as previous" {
  echo "x" >f.txt
  "$MINIGIT" add f.txt >/dev/null
  id=$("$MINIGIT" commit -m "first" | awk '{print $NF}')
  grep "Previous Commit ID: none" ".minigit/commits/$id/refs"
}

@test "commit: second commit refs points to first commit id" {
  echo "1" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  id1=$("$MINIGIT" commit -m "first" | awk '{print $NF}')

  echo "2" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  id2=$("$MINIGIT" commit -m "second" | awk '{print $NF}')

  grep "Previous Commit ID: $id1" ".minigit/commits/$id2/refs"
}

@test "commit: logs/commits_refs records the commit" {
  echo "x" >f.txt
  "$MINIGIT" add f.txt >/dev/null
  id=$("$MINIGIT" commit -m "msg" | awk '{print $NF}')
  grep "$id" .minigit/logs/commits_refs
}

@test "commit: index is empty after commit" {
  echo "x" >f.txt
  "$MINIGIT" add f.txt >/dev/null
  "$MINIGIT" commit -m "done" >/dev/null
  [ -z "$(ls -A .minigit/index)" ]
}

# error handling
@test "commit: no args prints usage" {
  run "$MINIGIT" commit
  [[ "$output" == *"Usage: minigit commit"* ]]
}

@test "commit: missing message prints usage" {
  run "$MINIGIT" commit -m
  [[ "$output" == *"Usage: minigit commit"* ]]
}

@test "commit: wrong flag prints usage" {
  run "$MINIGIT" commit -x "message"
  [[ "$output" == *"Usage: minigit commit"* ]]
}

@test "commit: empty index prints error" {
  run "$MINIGIT" commit -m "nothing"
  [[ "$output" == *"You cannot commit an empty index directory"* ]]
}

@test "commit: fails cleanly when .minigit missing" {
  rm -rf .minigit
  run "$MINIGIT" commit -m "x"
  [[ "$output" == *"Repository not initialized correctly"* ]]
}

# commits across branches
@test "commit: main and feature branches have different heads after their own commits" {
  echo "main" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "main commit" >/dev/null
  main_head=$(cat .minigit/heads/main)

  "$MINIGIT" branch new feature >/dev/null
  echo y | "$MINIGIT" branch switch feature >/dev/null

  echo "feature" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "feature commit" >/dev/null
  feature_head=$(cat .minigit/heads/feature)

  [ "$main_head" != "$feature_head" ]
}

@test "commit: commits from both branches coexist under .minigit/commits" {
  echo "main" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "main commit" >/dev/null
  main_head=$(cat .minigit/heads/main)

  "$MINIGIT" branch new feature >/dev/null
  echo y | "$MINIGIT" branch switch feature >/dev/null
  echo "feature" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "feature commit" >/dev/null
  feature_head=$(cat .minigit/heads/feature)

  [ -d ".minigit/commits/$main_head" ]
  [ -d ".minigit/commits/$feature_head" ]
}

@test "commit: committing on feature does not change main's head" {
  echo "main" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "main commit" >/dev/null
  main_head_before=$(cat .minigit/heads/main)

  "$MINIGIT" branch new feature >/dev/null
  echo y | "$MINIGIT" branch switch feature >/dev/null
  echo "feature" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "feature commit" >/dev/null

  [ "$(cat .minigit/heads/main)" = "$main_head_before" ]
}

# branch head movement across commits
@test "commit: head moves to new commit id after each commit on main" {
  echo "one" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  first_id=$("$MINIGIT" commit -m "first" | awk '{print $NF}')
  [ "$(cat .minigit/heads/main)" = "$first_id" ]

  echo "two" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  second_id=$("$MINIGIT" commit -m "second" | awk '{print $NF}')
  [ "$(cat .minigit/heads/main)" = "$second_id" ]
  [ "$first_id" != "$second_id" ]
}

@test "commit: after three commits head is latest, all three snapshots exist" {
  echo "1" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  id1=$("$MINIGIT" commit -m "1" | awk '{print $NF}')

  echo "2" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  id2=$("$MINIGIT" commit -m "2" | awk '{print $NF}')

  echo "3" >c.txt
  "$MINIGIT" add c.txt >/dev/null
  id3=$("$MINIGIT" commit -m "3" | awk '{print $NF}')

  [ "$(cat .minigit/heads/main)" = "$id3" ]
  [ -d ".minigit/commits/$id1" ]
  [ -d ".minigit/commits/$id2" ]
  [ -d ".minigit/commits/$id3" ]
}

@test "commit: feature branch head starts at main head and moves independently" {
  echo "main" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  main_id=$("$MINIGIT" commit -m "main1" | awk '{print $NF}')

  "$MINIGIT" branch new feature >/dev/null
  [ "$(cat .minigit/heads/feature)" = "$main_id" ]

  echo y | "$MINIGIT" branch switch feature >/dev/null
  echo "feat" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  feat_id=$("$MINIGIT" commit -m "feat1" | awk '{print $NF}')

  [ "$(cat .minigit/heads/feature)" = "$feat_id" ]
  [ "$(cat .minigit/heads/main)" = "$main_id" ]
}

@test "commit: directory commit moves head and snapshot has directory contents" {
  mkdir -p dir
  echo "content" >dir/file.txt
  "$MINIGIT" add . >/dev/null
  id=$("$MINIGIT" commit -m "with dir" | awk '{print $NF}')

  [ "$(cat .minigit/heads/main)" = "$id" ]
  [ -f ".minigit/commits/$id/snapshot/dir/file.txt" ]
}

@test "commit: removing file between commits moves head and new snapshot lacks removed file" {
  echo "keep" >a.txt
  echo "gone" >b.txt
  "$MINIGIT" add . >/dev/null
  id1=$("$MINIGIT" commit -m "both" | awk '{print $NF}')

  rm b.txt
  "$MINIGIT" add . >/dev/null
  id2=$("$MINIGIT" commit -m "removed b" | awk '{print $NF}')

  [ "$(cat .minigit/heads/main)" = "$id2" ]
  [ "$id1" != "$id2" ]
  [ -f ".minigit/commits/$id1/snapshot/b.txt" ]
  [ ! -f ".minigit/commits/$id2/snapshot/b.txt" ]
  [ -f ".minigit/commits/$id2/snapshot/a.txt" ]
}

@test "commit: removing directory between commits moves head and new snapshot lacks it" {
  mkdir -p dir
  echo "x" >dir/file.txt
  echo "top" >top.txt
  "$MINIGIT" add . >/dev/null
  id1=$("$MINIGIT" commit -m "with dir" | awk '{print $NF}')

  rm -rf dir
  "$MINIGIT" add . >/dev/null
  id2=$("$MINIGIT" commit -m "no dir" | awk '{print $NF}')

  [ "$(cat .minigit/heads/main)" = "$id2" ]
  [ -d ".minigit/commits/$id1/snapshot/dir" ]
  [ ! -e ".minigit/commits/$id2/snapshot/dir" ]
  [ -f ".minigit/commits/$id2/snapshot/top.txt" ]
}

# multi-branch workflow
@test "commit: multi-branch parallel workflow preserves state across switches" {
  echo "v1" >v1_file.txt
  "$MINIGIT" add v1_file.txt >/dev/null
  id_m1=$("$MINIGIT" commit -m "m1" | awk '{print $NF}')

  echo "stub" >feature.txt
  "$MINIGIT" add feature.txt >/dev/null
  id_m2=$("$MINIGIT" commit -m "m2" | awk '{print $NF}')

  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null

  [ "$(cat v1_file.txt)" = "v1" ]
  [ "$(cat feature.txt)" = "stub" ]

  echo "dev-changed" >v1_file.txt
  "$MINIGIT" add v1_file.txt >/dev/null
  id_d1=$("$MINIGIT" commit -m "d1" | awk '{print $NF}')

  echo "dev" >dev_only.txt
  "$MINIGIT" add dev_only.txt >/dev/null
  id_d2=$("$MINIGIT" commit -m "d2" | awk '{print $NF}')

  echo y | "$MINIGIT" branch switch main >/dev/null
  [ "$(cat v1_file.txt)" = "v1" ]
  [ "$(cat feature.txt)" = "stub" ]
  [ ! -e dev_only.txt ]
  [ "$(cat .minigit/heads/main)" = "$id_m2" ]

  echo "polished" >feature.txt
  "$MINIGIT" add feature.txt >/dev/null
  id_m3=$("$MINIGIT" commit -m "m3" | awk '{print $NF}')

  echo y | "$MINIGIT" branch switch dev >/dev/null
  [ "$(cat v1_file.txt)" = "dev-changed" ]
  [ -f dev_only.txt ]
  [ "$(cat dev_only.txt)" = "dev" ]
  [ "$(cat feature.txt)" = "stub" ]
  [ "$(cat .minigit/heads/dev)" = "$id_d2" ]

  [ -d ".minigit/commits/$id_m1" ]
  [ -d ".minigit/commits/$id_m2" ]
  [ -d ".minigit/commits/$id_m3" ]
  [ -d ".minigit/commits/$id_d1" ]
  [ -d ".minigit/commits/$id_d2" ]

  [ "$(cat .minigit/commits/$id_m1/snapshot/v1_file.txt)" = "v1" ]
  [ "$(cat .minigit/commits/$id_m2/snapshot/feature.txt)" = "stub" ]
  [ "$(cat .minigit/commits/$id_d1/snapshot/v1_file.txt)" = "dev-changed" ]
  [ "$(cat .minigit/commits/$id_d2/snapshot/dev_only.txt)" = "dev" ]
  [ "$(cat .minigit/commits/$id_m3/snapshot/feature.txt)" = "polished" ]
}

# deep tree across commits
@test "commit: deep tree with modifications and removals across commits" {
  mkdir -p a/b/c
  echo "deep" >a/b/c/deep.txt
  echo "mid" >a/b/mid.txt
  echo "shallow" >a/shallow.txt
  echo "top" >top.txt

  "$MINIGIT" add . >/dev/null
  id1=$("$MINIGIT" commit -m "full tree" | awk '{print $NF}')

  echo "deep-v2" >a/b/c/deep.txt
  rm a/b/mid.txt
  "$MINIGIT" add . >/dev/null
  id2=$("$MINIGIT" commit -m "modify + remove" | awk '{print $NF}')

  rm -rf a
  "$MINIGIT" add . >/dev/null
  id3=$("$MINIGIT" commit -m "nuke a/" | awk '{print $NF}')

  mkdir -p a
  echo "fresh" >a/new.txt
  "$MINIGIT" add . >/dev/null
  id4=$("$MINIGIT" commit -m "fresh a/" | awk '{print $NF}')

  [ "$(cat .minigit/heads/main)" = "$id4" ]

  [ "$id1" != "$id2" ]
  [ "$id2" != "$id3" ]
  [ "$id3" != "$id4" ]
  [ "$id1" != "$id4" ]

  [ "$(cat .minigit/commits/$id1/snapshot/a/b/c/deep.txt)" = "deep" ]
  [ "$(cat .minigit/commits/$id1/snapshot/a/b/mid.txt)" = "mid" ]
  [ "$(cat .minigit/commits/$id1/snapshot/a/shallow.txt)" = "shallow" ]
  [ "$(cat .minigit/commits/$id1/snapshot/top.txt)" = "top" ]

  [ "$(cat .minigit/commits/$id2/snapshot/a/b/c/deep.txt)" = "deep-v2" ]
  [ ! -e ".minigit/commits/$id2/snapshot/a/b/mid.txt" ]
  [ "$(cat .minigit/commits/$id2/snapshot/a/shallow.txt)" = "shallow" ]
  [ "$(cat .minigit/commits/$id2/snapshot/top.txt)" = "top" ]

  [ "$(cat .minigit/commits/$id3/snapshot/top.txt)" = "top" ]
  [ ! -e ".minigit/commits/$id3/snapshot/a" ]

  [ "$(cat .minigit/commits/$id4/snapshot/top.txt)" = "top" ]
  [ "$(cat .minigit/commits/$id4/snapshot/a/new.txt)" = "fresh" ]
  [ ! -e ".minigit/commits/$id4/snapshot/a/b" ]
  [ ! -e ".minigit/commits/$id4/snapshot/a/shallow.txt" ]
}
