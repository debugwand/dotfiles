# colour lookup found at http://www.ibm.com/developerworks/linux/library/l-tip-prompt/
D=$'\e[37m'
PINK=$'\e[35;40m'
GREEN=$'\e[32;40m'
RED=$'\e[31;40m'
ORANGE=$'\e[33;40m'
CYAN=$'\e[36;40m'
GREYBEIGEBOLD=$'\e[1;30;47m'

# by Jude Robinson, https://github.com/dotcode

function in_repo {
  (in_git_repo) && return
  return 1
}
function location_title {
  if in_repo; then
    local root=$(get_repo_root)
    local uroot="$(get_unversioned_repo_root)/"
    echo "${root/$uroot/} ($(get_repo_type))"
  else
    echo "${PWD/$HOME/~}"
  fi
}

function get_repo_type {
  in_git_repo && echo -ne "git" && return
  return 1
}

function get_repo_branch {
  in_git_repo && echo $(git branch | grep '*' | cut -d ' ' -f 2) && return
  return 1
}

function get_main_branch_name () {
  in_git_repo && echo "master" && return
  return 1
}

function get_repo_status {
  in_git_repo && git status --porcelain && return
  return 1
}

function get_repo_root {
  in_git_repo && echo $(git rev-parse --show-toplevel) && return
  return 1
}

function get_unversioned_repo_root {
  local lpath="$1"
  local cPWD=`echo $PWD`

  # see if $lpath is non-existent or empty, and if so, assign
  if test ! -s "$lpath"; then
    local lpath=`echo $PWD`
  fi

  cd "$lpath" &> /dev/null
  local repo_root="$(get_repo_root)"

  # see if $repo_root is non-existent or empty, and if so, assign
  if test ! -s "$repo_root"; then
      echo $lpath
  else
    local parent="${lpath%/*}"
    get_unversioned_repo_root "$parent"
  fi

    cd "$cPWD" &> /dev/null
}
function repo_status {
  # set locations
  local here="$PWD"
  local user_root="$HOME"
  local repo_root="$(get_repo_root)"

  local root="`get_unversioned_repo_root`/"
  local lpath="${here/$root/}"

  # set colours
  local root_color=$'\e[32;40m' # green
  local path_color=$'\e[35;40m' # pink
  local no_color=$'\e[37m' # empty
  local alert_color=$'\e[31;40m' # red

  # get branch information - empty if no (or default) branch
  local branch=$(get_repo_branch)
  if [[ $branch != '' ]]; then
    local branch=" at \033[4m${branch}\033[0m" # underline branch name
  fi

  # status of current repo
  if in_git_repo; then
    local lstatus=`get_repo_status | sed 's/^ */g/'`
  else
    local lstatus=''
  fi

  # printf "\n\n status_count = $status_count \n\n"
  local status_count=`echo "$lstatus" | wc -l | awk '{print $1}'`
  # printf "\n\n status_count = $status_count \n\n"

  # if there's anything to report on...
  if [[ "$status_count" -gt 0 ]]; then

    local changes=""

    # modified file count
    local modified="$(echo "$lstatus" | grep -c '^[gm]M')"
    if [[ "$modified" -gt 0 ]]; then
      changes="$modified changed"
    fi

    # added file count
    local added="$(echo "$lstatus" | grep -c '^[gm]A')"
    if [[ "$added" -gt 0 ]]; then
      if [[ "$changes" != "" ]]; then
        changes="${changes}, "
      fi
      changes="${changes}${added} added"
    fi

    # removed file count
    local removed="$(echo "$lstatus" | grep -c '^(mR|gD)')"
    if [[ "$removed" -gt 0 ]]; then
      if [[ "$changes" != "" ]]; then
        changes="${changes}, "
      fi
      changes="${changes}${removed} removed"
    fi

    # renamed file count
    local renamed="$(echo "$lstatus" | grep -c '^gR')"
    if [[ "$renamed" -gt 0 ]]; then
      if [[ "$changes" != "" ]]; then
        changes="${changes}, "
      fi
      changes="${changes}${removed} renamed"
    fi

    # missing file count
    local missing="$(echo "$lstatus" | grep -c '^m!')"
    if [[ "$missing" -gt 0 ]]; then
      if [[ "$changes" != "" ]]; then
        changes="${changes}, "
      fi
      changes="${changes}${missing} missing"
    fi

    # untracked file count
    local untracked="$(echo "$lstatus" | grep -c '^[gm]?')"
    if [[ "$untracked" -gt 0 ]]; then
      if [[ "$changes" != "" ]]; then
        changes="${changes}, "
      fi
      changes="${changes}${untracked} untracked"
    fi

    if [[ "$changes" != "" ]]; then
      changes=" (${changes})"
    fi

  fi

  echo -e "${root_color}${root}${path_color}${lpath}${no_color}${branch}${alert_color}${update}${changes}" # ${root_color} $(prompt_char) $(get_repo_type) ${no_color}"
}

# display current path
function ps_status {
  in_repo && repo_status && return

  local open_color=$'\e[32;40m' # green
  local close_color=$'\e[37m' # empty

  echo -e "${open_color}${PWD/#$HOME/~} ${close_color}"
}
function in_git_repo {
  git branch > /dev/null 2>&1 && return
  return 1
}
function prompt_char {
  in_git_repo && echo -ne '±' && return
  echo '$'
}
export PS1='${CYAN}\u ${D}at ${ORANGE}\h ${D}in ${GREEN}$(ps_status) ${D}$(date +%k:%M:%S) \n$(prompt_char)\[\033[0m\] '
export DISPLAY=:0.0
