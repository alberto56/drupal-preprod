#!/bin/bash
#
# Cycles through all subfolders in the current folder, and for each folder
# looks for a file called delete.txt; if that file exists, and contains a
# timestamp which is lower than the current time, then delete not only the
# folder, but the /etc/hosts entry, the vhosts entry, the database and anything
# else that made up that website.

set -e

# @param $1
#   The directory name, e.g. myproject-master-abc123

for f in *; do
  if [[ -d $f ]]; then
    if [ $f != 'tmp' ]; then
      if [ -e $f/delete.txt ]; then
        if [ $(date +%s) -gt $(cat "$f/delete.txt") ]; then
          echo ""
          echo "$(date +%s) is greater than $(cat "$f/delete.txt")"
          echo "so we will delete the site $f"
          echo "Removing the directory $f"
          echo ""
          chmod -R u+w "$f"
          rm -rf $f
          echo ""
          echo "Removing entries conaining $f in /etc/hosts"
          # can't use sed -i here because sed -i generates a temporary files
          # which can't be used because of permissions.
          sed "/$f/d" /etc/hosts > ~/etchosts
          cat ~/etchosts > /etc/hosts
          rm ~/etchosts
          echo ""
          source ~/.drupal-preprod.variables
          DBNAME=$(echo $f|sed -e 's/-//g')
          echo "Deleting the database $DBNAME""preprod"
          echo "drop database IF EXISTS $DBNAME""preprod" |mysql -uroot -p$MYSQLPASS
          echo "Deleting the database $DBNAME""new"
          echo "drop database IF EXISTS $DBNAME""new" |mysql -uroot -p$MYSQLPASS
          echo ""
          CONFFILE="/var/lib/jenkins/conf.d/$f.preprod.conf"
          echo "Removing $CONFFILE"
          rm -f $CONFFILE
          CONFFILE="/var/lib/jenkins/conf.d/$f.new.conf"
          echo "Removing $CONFFILE"
          rm -f $CONFFILE
          echo ""
          echo "Removing lines containing $f in the index.hml"
          sed -i "/$f/d" drupal-preprod-index/index.html
        fi
      fi
    fi
  fi
done
