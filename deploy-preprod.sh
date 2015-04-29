#!/bin/bash
#
# Deploys a new Drupal site using a clone of another site by loading its files and
# database.

set -e

if [ "$#" -eq "0" ]
  then
    echo "Deploys a new site using an cloned database and files."
    echo ""
    echo "Usage:"
    echo ""
    echo "./deploy-preprod.sh -d /path/to/drupal -f 'https://example.com/files.tar.gz -b http://example.com/database.sql.gz'"
else
  while getopts ":d:f:b:" opt; do
    case $opt in
      d) DIR="$OPTARG"
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

  echo "Path is $DIR" &&
  echo "" &&
  cd "$DIR" &&
  echo "drop database $DBNAME; create database $DBNAME charset utf8;" | drush sqlc
  mkdir -p ~/$PROJECT
  wget --progress=dot:giga -N $FILES -P ~/$PROJECT
  tar -xzf ~/$PROJECT/*.tar.gz
  wget --progress=dot:giga -N $DB -P ~/$PROJECT
  zcat ~/$PROJECT/*.sql.gz | drush sqlc

fi
