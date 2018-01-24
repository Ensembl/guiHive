#!/bin/bash

DEFAULT_DEPLOY_LOCATION="$(dirname "$0")"
DEPLOY_LOCATION=${DEPLOY_LOCATION:-$DEFAULT_DEPLOY_LOCATION}

EHIVE_CLONE_LOCATION="${DEPLOY_LOCATION}/clones/ensembl-hive"
GUIHIVE_CLONE_LOCATION="${DEPLOY_LOCATION}/clones/guiHive"
EHIVE_VERSIONS_DIR="${DEPLOY_LOCATION}"/ensembl-hive
GUIHIVE_VERSIONS_DIR="${DEPLOY_LOCATION}"/versions

    # if you specify a new EHIVE_SOURCE, the Hive cache will be automatically cleaned up:
if [ -n "$EHIVE_SOURCE" ]
then
    echo "RM " rm -rf "$EHIVE_CLONE_LOCATION" "$EHIVE_VERSIONS_DIR"
    rm -rf "$EHIVE_CLONE_LOCATION" "$EHIVE_VERSIONS_DIR"
fi

    # if you specify a new EHIVE_SOURCE, the guiHive cache will be automatically cleaned up:
if [ -n "$GUIHIVE_SOURCE" ]
then
    echo "RM " rm -rf "$GUIHIVE_CLONE_LOCATION" "$GUIHIVE_VERSIONS_DIR"
    rm -rf "$GUIHIVE_CLONE_LOCATION" "$GUIHIVE_VERSIONS_DIR"
fi

EHIVE_DEFAULT_SOURCE='git://www.github.com/Ensembl/ensembl-hive'
EHIVE_SOURCE=${EHIVE_SOURCE:-$EHIVE_DEFAULT_SOURCE}

GUIHIVE_DEFAULT_SOURCE='git://www.github.com/Ensembl/guiHive'
GUIHIVE_SOURCE=${GUIHIVE_SOURCE:-$GUIHIVE_DEFAULT_SOURCE}

umask 0002

if [ -d "$GUIHIVE_VERSIONS_DIR" ] && [ -d "$EHIVE_VERSIONS_DIR" ]
then
  echo "'$GUIHIVE_VERSIONS_DIR' and/or '$EHIVE_VERSIONS_DIR' already exist. Press ctrl+c to exit now, or enter otherwise/"
  read
fi

mkdir -p "$DEPLOY_LOCATION"
mkdir -p "$GUIHIVE_VERSIONS_DIR"
mkdir -p "$EHIVE_VERSIONS_DIR"

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
    echo "GITCLONE: " git clone --mirror "$1" "$2"
    git clone --mirror "$1" "$2"
  fi
}

reference_clone "$EHIVE_SOURCE" "$EHIVE_CLONE_LOCATION"
reference_clone "$GUIHIVE_SOURCE" "$GUIHIVE_CLONE_LOCATION"

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

trim_ehive_repo () {
  # $dir
  rm -rf "$1/docs"
  rm -rf "$1/wrappers"
  rm -rf "$1/scripts"
  rm -rf "$1/t"
}

add_guihive_version () {
  echo "checkout $1: guiHive $2 and eHive $3"
  safe_clone "$2" "$GUIHIVE_CLONE_LOCATION" "${GUIHIVE_VERSIONS_DIR}/$1"
  safe_clone "$3" "$EHIVE_CLONE_LOCATION" "${EHIVE_VERSIONS_DIR}/$1"
  trim_ehive_repo "${EHIVE_VERSIONS_DIR}/$1"
}

link_guihive_version () {
  DEFAULT_TAG="sql_schema_$((${1}+1))_start^"
  EHIVE_COMMIT=${3:-$DEFAULT_TAG}
  echo "checkout $1: guiHive =$2 and eHive $EHIVE_COMMIT"
  safe_symlink "$2" "${GUIHIVE_VERSIONS_DIR}/$1"
  safe_clone "$EHIVE_COMMIT" "$EHIVE_CLONE_LOCATION" "${EHIVE_VERSIONS_DIR}/$1"
  trim_ehive_repo "${EHIVE_VERSIONS_DIR}/$1"
}


## Checkout the server branch

if [ -e "$DEPLOY_LOCATION/README.md" ]
then
  echo "$DEPLOY_LOCATION/README.md is there, assuming the server branch is checked out"
else
  #safe_clone server "$GUIHIVE_CLONE_LOCATION" "$DEPLOY_LOCATION"
  GIT_DIR="$GUIHIVE_CLONE_LOCATION" GIT_WORK_TREE="$DEPLOY_LOCATION" git checkout -qf 'server'
fi

## List of versions

# 1. First we list all the eHive stable branches + master and map them to their database versions
#    In case several branches are based on the same schema, we keep the latest.
#    We also list specific guiHive versions that were made whilst developing eHive's master
# $db_version  guihive_branch  ehive_branch
add_guihive_version "56" "db_version/56" "version/2.0"
add_guihive_version "62" "db_version/62" "version/2.2"
add_guihive_version "73" "db_version/73" "version/2.3"
add_guihive_version "80" "db_version/80" "version/2.4"
add_guihive_version "84" "db_version/84" "sql_schema_85_start~3"
add_guihive_version "88" "db_version/88" "sql_schema_89_start^"
add_guihive_version "89" "db_version/89" "sql_schema_90_start^"
add_guihive_version "91" "db_version/91" "sql_schema_92_start^"

# 2. Then we list all the other eHive database versions and link them to a compatible guiHive version

# $db_version  $aliased_db_version
# 57 to 61 are skipped
link_guihive_version "63" "62"
link_guihive_version "64" "73"
link_guihive_version "65" "73"
link_guihive_version "66" "73"
link_guihive_version "67" "73"
link_guihive_version "68" "73"
link_guihive_version "69" "73"
link_guihive_version "70" "73" "sql_schema_71_start^2"	# because the merge of the python branch has swapped its two parents
link_guihive_version "71" "73"
link_guihive_version "72" "73"
# 73 is listed in the first section
link_guihive_version "74" "80"
link_guihive_version "75" "80" "44d78112401c21e2a704b8335dd4b247b85fe93a"  # this is the last "safe" commit for guiHive 75, i.e. before Utils/Graph starts printing extra messages on stdout
link_guihive_version "76" "80"
link_guihive_version "77" "80"
link_guihive_version "78" "80"
link_guihive_version "79" "80"
# 80 is listed in the first section
link_guihive_version "81" "80"
link_guihive_version "82" "80"
link_guihive_version "83" "80"
# 84 is listed in the first section
link_guihive_version "85" "88"
link_guihive_version "86" "88"
link_guihive_version "87" "88"
# 88 is listed in the first section
# 89 is listed in the first section
link_guihive_version "90" "89"
# 91 is listed in the first section
link_guihive_version "92" "91" "master"

trap - EXIT

