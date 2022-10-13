#!/usr/bin/env bash

# Author  : Ky-Anh Huynh
# Purpose : Check if links in Markdown files are broken

list_links() {
  grep -Eoe '\[[^]]+\]\([^)]+\)' \
  | awk -F '\\]\\(' '{print substr($NF,0, length($NF) - 1)}' \
  | grep -v '^#' \
  | grep -v '^http' \
  | awk -F '#' '{print $1}' \
  | sed -e 's|/$|/README.md|'
}

default_check() {
  path="${1:-.}"
  err=0
  while read -r path; do
    (
      cd "$path" || exit
      s_err=0
      while read -r md_file; do
        while read -r link; do
          if [[ ! -f "$link" && ! -d "$link" ]]; then
            echo >&2 ":: Broken link in $path/$md_file : $link"
            (( s_err ++ ))
          fi
        done < <(list_links < "$md_file")
      done < <( \
        find . -maxdepth 1 -mindepth 1 -type f -iname "*.md"
      )
      [[ "$s_err" -eq 0 ]]
    )

    [[ $? -ge 1 ]] && (( err++ ))
  done < <(find "$path" -type d)
  [[ $err -eq 0 ]]
}

"${@:-default_check}"
