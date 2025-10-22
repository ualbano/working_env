#!/bin/bash

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Exactly one argument needed: The name of the branch that should be used to open a PR."
  exit 1
fi

branch="$1"
target="$2"
range="$target..$branch"

profile=DeveloperDevAccess
repo=$(basename $(git rev-parse --show-toplevel))
region=eu-central-1

num_commits=$(git rev-list --count "$range")
tfile="$(mktemp)"

if [[ $num_commits != 1 ]]; then

  git log "$range" >$tfile
  "${EDITOR:-vi}" "$tfile"
  message_raw=$(cat "$tfile")
  rm "$tfile"
  summary="$(echo "$message_raw" | head -n 1)"
  message="$(echo "$message_raw" | tail -n +2)"
  #echo "There are $num_commits commits in the branch, but only one is allowed."
  #exit 1
else
  summary="$(git rev-list --pretty=format:%s "$range" | tail -n +2)"
  message="$(git rev-list --pretty=format:%B "$range" | tail -n +4)"
fi

echo "Please confirm PR creation with the following details:"
echo "- Repo: $repo"
echo "- target: $target"
echo "- source branch: $branch"
echo "- summary message: $summary"
echo "- Commit message:"
echo "$message"
echo

read -p "Should the PR be created? (y/n)" -n 1
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  : okay, continue
else
  exit 1
fi

set -x

git push origin "$branch"
glab mr create -s "$branch" -b "$target" -t "$summary" -d "$message"
