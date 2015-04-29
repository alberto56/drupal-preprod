#!/bin/bash
#
# Given a commit number, provides a login URL for all the existing environments.
# Usage: see README.md

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "uli.sh"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"

source ~/.drupal-preprod.variables

if [ -z "$MAINWORKSPACE" ]
  then
    echo -e "[error] Please set MAINWORKSPACE in ~/.drupal-preprod.variables to whatever"
    echo -e "        the path of your preprod job on Jenkins. See"
    echo -e "        https://github.com/alberto56/drupal-preprod for details."
    exit 1;
  else
    echo -e "[info] MAINWORKSPACE is set to $MAINWORKSPACE"
fi

if [ -z "$1" ]
  then
    echo -e "[error] Please call this with a commit number.."
    exit 1;
  else
    echo -e "[info] Using commit number $1"
fi

set -e

# @param $1
#   The directory name, e.g. myproject-master-abc123

for f in "$MAINWORKSPACE"; do
  if [[ -d $f ]]; then
    if [ $f != 'tmp' ]; then
      echo $f | grep -v $1 || echo -e "\n\n" && cd $f && drush uli && drush uli authenticated && echo -e "\n\n" && cd ..
    fi
  fi
done

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "uli.sh end of script"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"
