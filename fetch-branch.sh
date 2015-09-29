#!/bin/bash

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "fetch-branch.sh"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"

# @param $1
#   name of an environment, normally new or preprod
function addEnvironment {
  echo -e "[info] About to create the $1 environment"

  if [ -d "$SUBDIR/$1" ]
    then
      if [ ! -e "$SUBDIR/$1/sites/default/settings.php" ]
        then
          echo -e "[warning] The $1 environment already exists, but has not been properly built"
          echo -e "          because $SUBDIR/$1/sites/default/settings.php does not"
          echo -e "          exist".
          echo -e "          We will delete the entire environment".
          rm -rf "$SUBDIR/$1"
      fi
  fi

  if [ ! -d "$SUBDIR/$1" ]; then
    mkdir -p "$SUBDIR" &&
    cd "$SUBDIR" &&
    git clone ../ $1 &&
    cd $1 &&
    drush si -y --db-url=mysql://root:$MYSQLPASS@localhost/$DBNAME$1 minimal &&
    drush user-create authenticated &&
    chmod u+w $(pwd -P)/sites/default/settings.php

    domain $1
    echo '$'"base_url = \"http://$DOMAIN\";" >> sites/default/settings.php
    grep "126.0.0.1 $DOMAIN" /etc/hosts || echo "127.0.0.1 $DOMAIN" >> /etc/hosts
    echo "[info] Adding vhost entry to $IDENTITY.$1.conf"
    echo "<VirtualHost *:80>" > /var/lib/jenkins/conf.d/$IDENTITY.$1.conf
    echo "  DocumentRoot \"$SUBDIR/$1\"" >> /var/lib/jenkins/conf.d/$IDENTITY.$1.conf
    echo "  ServerName $DOMAIN" >> /var/lib/jenkins/conf.d/$IDENTITY.$1.conf
    echo "  <Directory />" >> /var/lib/jenkins/conf.d/$IDENTITY.$1.conf
    echo "    Allow from all" >> /var/lib/jenkins/conf.d/$IDENTITY.$1.conf
    echo "  </Directory>" >> /var/lib/jenkins/conf.d/$IDENTITY.$1.conf
    echo "</VirtualHost>" >> /var/lib/jenkins/conf.d/$IDENTITY.$1.conf

    INDEX="$DIR/drupal-preprod-index/index.html"
    echo -e "[info] About to add a hyperlink to $INDEX"

    grep $IDENTITY-$1 "$INDEX" ||  echo "<div><a target=\"_blank\" href=\"http://$DOMAIN\" class=\"$IDENTITY-$1\" id=\"$IDENTITY\">$PROJECT: Commit $HASH of branch $BRANCH ($1) on $(date)</a></div>" >> "$INDEX"

  fi
}

# @param $1
#   name of an environment, normally new or preprod
function domain {
  DOMAIN=$DOMAINBEFORE"$SANITIZEDIDENTITY-$1"$DOMAINAFTER
}

# @param $1
#   name of an environment, normally new or preprod
function uli {
  cd "$SUBDIR/$1" &&
  echo -e "[info] About to generate user 1 one-time login link for $SUBDIR/$1" &&
  drush uli &&
  echo -e "[info] About to generate authenticated user one-time login link for $SUBDIR/$1" &&
  drush uli authenticated
}

set -e

if [ "$#" -eq "0" ]
  then
    echo "Fetches a branch for a given repo, and then adds a link to it on the index"
    echo "of the given repo."
    echo ""
    echo "Usage:"
    echo ""
    echo "Start by creating a file called ~/.drupal-preprod.variables with MYSQLPASS=mypassword"
    echo ""
    echo "-z : delete in number of days. This creates a file called delete.txt in repo/HASH which contains a timestamp"
    echo "     in a set number of days, so that it can get deleted automatically"
    echo ""
    echo "./fetch-branch.sh -z 5 -h subdir -d /path/to/repo -r ssh://me@git.example.com/project -b master -p myprojectname"
else
  while getopts ":z:p:d:r:b:h:" opt; do
    case $opt in
      z) DELETE="$OPTARG"
      ;;
      p) PROJECT="$OPTARG"
      ;;
      d) DIR="$OPTARG"
      ;;
      r) REPO="$OPTARG"
      ;;
      b) BRANCH="$OPTARG"
      ;;
      h) HASH="$OPTARG"
      ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  source ~/.drupal-preprod.variables
  if [ -z "$DELETE" ]; then echo "[error] The argument -z is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$PROJECT" ]; then echo "[error] The argument -p is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$DIR" ]; then echo "[error] The argument -d is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$REPO" ]; then echo "[error] The argument -r is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$BRANCH" ]; then echo "[error] The argument -b is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$HASH" ]; then echo "[error] The argument -h is not set. Execute with no arguments for usage."; exit 1; fi
  if [ -z "$MYSQLPASS" ]; then echo "[error] MYSQLPASS not set. Execute with no arguments for usage."; exit 1; fi

  SANITIZEDPROJECT=$(echo $PROJECT|sed -e 's/_/-/g')
  SANITIZEDBRANCH=$(echo $BRANCH|sed -e 's/\///g')
  IDENTITY="$PROJECT-$SANITIZEDBRANCH-$HASH";
  SANITIZEDIDENTITY="$SANITIZEDPROJECT-$SANITIZEDBRANCH-$HASH"
  SUBDIR="$DIR/$IDENTITY";
  DBNAME=$(echo $IDENTITY|sed -e 's/-//g')
  echo "[info] We have determined that the directories in which to put the environments"
  echo "       are $SUBDIR/preprod"
  echo "       and $SUBDIR/new"

  addEnvironment preprod
  addEnvironment new
  sudo apachectl restart
  uli preprod
  uli new

  echo $(echo "$(date +%s)+$DELETE*24*60*60"|bc) > "$SUBDIR/delete.txt"

fi

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "fetch-branch.sh end of script"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"
