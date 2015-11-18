#!/bin/sh

GUIHIVE_URL='http://www.github.com/Ensembl/guiHive'
EHIVE_URL='http://www.github.com/Ensembl/ensembl-hive'

DEPLOY_LOCATION="$(dirname "$0")"
EHIVE_CLONE_LOCATION="${DEPLOY_LOCATION}/clones/ensembl-hive"
GUIHIVE_CLONE_LOCATION="${DEPLOY_LOCATION}/clones/guiHive"
GUIHIVE_VERSIONS_DIR="${DEPLOY_LOCATION}"/versions
EHIVE_VERSIONS_DIR="${DEPLOY_LOCATION}"/ensembl-hive

# Any failure will cause the script to exit
trap "echo 'An error occurred. Deployment aborted'; exit 1" EXIT
set -e

reference_clone () {
  # $git_url $target_dir
  echo "get reference clone for $2 from $1"
  if [ -d "$2" ]
  then
    GIT_DIR="$2" git fetch
  else
    git clone --mirror "$1" "$2"
  fi
}

reference_clone "$EHIVE_URL" "$EHIVE_CLONE_LOCATION"
reference_clone "$GUIHIVE_URL" "$GUIHIVE_CLONE_LOCATION"

## "Safe" functions that can deal with pre-incarnations of the target

safe_clone () {
  # safe_clone $branch $URL $dest
  rm -rf "$3"
  mkdir -p "$3"
  GIT_DIR="$2" GIT_WORK_TREE="$3" git checkout -qf "$1"
}

safe_symlink () {
  # safe_symlink $source $target
  rm -rf "$2"
  ln -s "$1" "$2"
}


## Higher-level functions that wrap the safe functions

add_guihive_version () {
  echo "checkout $1: guiHive $2 and eHive $3"
  safe_clone "$2" "$GUIHIVE_CLONE_LOCATION" "${GUIHIVE_VERSIONS_DIR}/$1"
  safe_clone "$3" "$EHIVE_CLONE_LOCATION" "${EHIVE_VERSIONS_DIR}/$1"
  rm -rf "${EHIVE_VERSIONS_DIR}/$1/docs"
  rm -rf "${EHIVE_VERSIONS_DIR}/$1/wrappers"
}

link_guihive_version () {
  echo "checkout $1: guiHive =$2 and eHive sql_$1"
  safe_symlink "$2" "${GUIHIVE_VERSIONS_DIR}/$1"
  safe_clone "sql_schema_$((${1}+1))_start^" "$EHIVE_CLONE_LOCATION" "${EHIVE_VERSIONS_DIR}/$1"
  rm -rf "${EHIVE_VERSIONS_DIR}/$1/docs"
  rm -rf "${EHIVE_VERSIONS_DIR}/$1/wrappers"
}


## List of versions

# $db_version  guihive_branch  ehive_branch
add_guihive_version "56" "db_version/56" "version/2.0"
add_guihive_version "62" "db_version/62" "version/2.2"
add_guihive_version "73" "db_version/73" "version/2.3"
add_guihive_version "77" "db_version/77" "master"

# $db_version  $aliased_db_version
link_guihive_version "63" "62"
link_guihive_version "64" "73"
link_guihive_version "65" "73"
link_guihive_version "66" "73"
link_guihive_version "67" "73"
link_guihive_version "68" "73"
link_guihive_version "69" "73"
link_guihive_version "70" "73"
link_guihive_version "71" "73"
link_guihive_version "72" "73"
link_guihive_version "74" "73"
link_guihive_version "75" "73"
link_guihive_version "76" "77"

trap - EXIT

