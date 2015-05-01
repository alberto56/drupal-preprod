#!/bin/bash
#
# Deploys a new Drupal site using a clone of another site by loading its files and
# database.

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "deploy-preprod.sh"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"

set -e

if [ "$#" -eq "0" ]
  then
    echo "Deploys a new site using an cloned database and files."
    echo ""
    echo "Usage:"
    echo ""
    echo "./deploy-preprod.sh -p project -h abc123 -d /path/to/drupal -f 'https://example.com/files.tar.gz -b http://example.com/database.sql.gz'"
else
  while getopts ":d:f:b:r:p:h:" opt; do
    case $opt in
      p) PROJECT="$OPTARG"
      ;;
      h) HASH="$OPTARG"
      ;;
      d) DIR="$OPTARG"
      ;;
      d) BRANCH="$BRANCH"
      ;;
      f) FILES="$OPTARG"
      ;;
      b) DB="$OPTARG"
      ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  source ~/.drupal-preprod.variables
  source ~/.bash_profile

  if [ -z "$DIR" ]; then echo "The argument -d is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$FILES" ]; then echo "The argument -f is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$DB" ]; then echo "The argument -b is not set. Execute with no arguments for usage."; exit 1; fi

  SANITIZEDBRANCH=$(echo $BRANCH|sed -e 's/\///g')
  IDENTITY="$PROJECT-$SANITIZEDBRANCH-$HASH";
  SUBDIR="$DIR/$IDENTITY";
  DBNAME=$(echo $IDENTITY|sed -e 's/-//g')

  if [ -z "$BRANCH" ]; then echo -e "[error] Internal error: the variable BRANCH is not set."; exit 1; fi
  if [ -z "$PROJECT" ]; then echo -e "[error] Internal error: the variable PROJECT is not set."; exit 1; fi
  if [ -z "$HASH" ]; then echo -e "[error] Internal error: the variable HASH is not set."; exit 1; fi
  if [ -z "$SANITIZEDBRANCH" ]; then echo -e "[error] Internal error: the variable SANITIZEDBRANCH is not set."; exit 1; fi
  if [ -z "$IDENTITY" ]; then echo -e "[error] Internal error: the variable IDENTITY is not set."; exit 1; fi
  if [ -z "$SUBDIR" ]; then echo -e "[error] Internal error: the variable SUBDIR is not set."; exit 1; fi
  if [ -z "$DBNAME" ]; then echo -e "[error] Internal error: the variable DBNAME is not set."; exit 1; fi
  if [ -z "$DIR" ]; then echo -e "[error] Internal error: the variable DIR is not set."; exit 1; fi

  echo "[info] BRANCH is $BRANCH"
  echo "[info] SANITIZEDBRANCH is $SANITIZEDBRANCH"
  echo "[info] IDENTITY is $IDENTITY"
  echo "[info] SUBDIR is $SUBDIR"
  echo "[info] DBNAME is $DBNAME"
  echo "[info] DIR is $DIR"
  cd "$DIR" &&
  echo "drop database $DBNAME; create database $DBNAME charset utf8;" | drush sqlc
  mkdir -p ~/$PROJECT
  wget --progress=dot:giga -N $FILES -P ~/$PROJECT
  tar -xzf ~/$PROJECT/*.tar.gz
  wget --progress=dot:giga -N $DB -P ~/$PROJECT
  zcat ~/$PROJECT/*.sql.gz | drush sqlc

fi

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "deploy-preprod.sh end of script"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"
