#!/bin/bash
# Send e-mail reminder for changes staged for release
#
#  Copyright (C) 2015 LoVullo Associates, Inc.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

get-latest-tag()
{
  local -r refspec="${1?Missing refspec}"

  git describe --abbrev=0 "$refspec"
}


ls-staged-commits()
{
  local -r refspec="${1?Missing refspec}"
  local -r latest_tag=$( get-latest-tag "$refspec" )

  test -n "$latest_tag" || return

  # friendly (and hopefully unambiguous?) repository name, with .git
  # stripped (since this may be run on bare repositories)
  local -r repo_name=$( basename "$(pwd)" .git )

  # list all commits to the mainline (e.g. merges or commits directly on
  # a branch) with the repo name, refspec, author, and subject line
  git log --first-parent \
      --pretty="$repo_name:$refspec %h (%an) %s" \
      "$latest_tag"..
}


with-repo-ref()
{
  local -r spec="${1?Missing repo:refspec spec}"
  local -r cmd="${2?Missing command}"
  shift 2

  local repo_path refspec
  IFS=: read repo_path refspec <<< "$spec"

  (
    cd "$repo_path" \
       && "$cmd" "${refspec:-master}" "$@"
  )
}


with-each-repo-spec()
{
  local -r cmd="${1?Missing command}"
  shift

  local -i fail=0

  while [ $# -gt 0 ]; do
    with-repo-ref "$1" "$cmd" || ((fail++))
    shift
  done

  test "$fail" -eq 0
}
