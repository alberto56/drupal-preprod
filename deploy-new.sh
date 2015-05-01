#!/bin/bash
#
# Deploys a new Drupal site using its site deployment module and potentially its
# devel module. See http://dcycleproject.org/blog/44/what-site-deployment-module

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "deploy-new.sh"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"

set -e

if [ "$#" -eq "0" ]
  then
    echo "Deploys a new site and populates it with realistic dummy content if possible."
    echo ""
    echo "Usage:"
    echo ""
    echo "./deploy-new.sh -d /path/to/drupal -m 'mysite_deploy mysite_devel'"
else
  while getopts ":d:m:" opt; do
    case $opt in
      d) DIR="$OPTARG"
      ;;
      m) MODULES="$OPTARG"
      ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  source ~/.drupal-preprod.variables
  source ~/.bash_profile

  if [ -z "$DIR" ]; then echo "The argument -d is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$MODULES" ]; then echo "The argument -m is not set. Execute with no arguments for usage."; exit 1; fi

  echo -e "[info] Path is $DIR"
  cd "$DIR"
  echo -e "[info] Currently in $(pwd)"
  echo -e "[info] Contents of sites/default:"
  ls -lah sites/default
  echo "[info] Modules are $MODULES"

  /bin/drush -y en $MODULES &&
  /bin/drush generate-realistic || true  &&
  /bin/drush uli &&
  /bin/drush uli authenticated
fi

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "deploy-new.sh end of script"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"
