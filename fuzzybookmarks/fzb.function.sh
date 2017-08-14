# Setup FuzZyBookmarks (fzb) function
# ------------------
export FZB_LIST=fuzzybookmarks_list #can also be a path
export FZB_GLOB=fuzzybookmarks_glob #can also be a path
export FZB_SYSTEMWIDE_BOOKMARKS=/etc/fuzzybookmarks_paths
export FZB_USER_BOOKMARKS=~/.config/fuzzybookmarks/paths
#export FZB_SORT='sort -u'
export FZB_SORT='cat'
export FZB_DEL_SORT=$FZB_SORT

function _fzb_select {
  local res #first declare as local, or else the returncode won't work. # see http://tldp.org/LDP/abs/html/localvar.html section 24-12
  res=$($FZB_GLOB) || return $?

  local query
  query=${1:+-q $1}

  local bookmark
  bookmark=$(echo "$res" | fzf -0 -1 $query --preview="ls {1}")
  echo "${bookmark}"
}

unalias fzb 2> /dev/null
fzb() {
  local dest_dir

  dest_dir=$(_fzb_select "${@}")
  if [[ "$dest_dir" != '' ]]; then
     cd $(echo "$dest_dir" | cut -f 1 -d " ")
  fi
}
fzb-add () {
  echo "${PWD} # $*" >> "$FZB_USER_BOOKMARKS"
}

# fzb-del depends on `sponge` from moreutils package.
fzb-del () {
  local bookmark
  bookmark=$(_fzb_select "${@}")
  if [[ "$bookmark" != '' ]]; then
    #FIXME: this will kinda require bookmark entries to always have a # comment, otherwise selecting /path/to would also remove /path/to/subdir or /path/too
    grep -Fv "${bookmark}" "${FZB_USER_BOOKMARKS}" | $FZB_DEL_SORT | sed -E '/^\s*$/d' |sponge "${FZB_USER_BOOKMARKS}"
  fi
}

export -f fzb > /dev/null
export -f fzb-add > /dev/null
export -f fzb-del > /dev/null
