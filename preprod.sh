echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "preprod.sh"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"

PROJECT=$1
BRANCH=$2
DELETE=$3

echo -e "\nProject is $PROJECT"
echo -e "Branch is $BRANCH"
echo -e "Project set to be deleted in $DELETE\n"

if [ -z $PROJECT ]
  then
    echo -e "\nExiting: you must specify the project.\n"
    exit 1
fi
if [ -z $BRANCH ]
  then
    echo -e "\nExiting: you must specify the branch.\n"
    exit 1
fi
if [ -z $DELETE ]
  then
    echo -e "\nExiting: you must specify the number of days to keep this live even if it's zero (0).\n"
    exit 1
fi

HASH=$(git log -n1 --pretty='%h')

if [ -c ./scripts/deploy/drupal-preprod-info.sh ]
  then
    source ./scripts/deploy/drupal-preprod-info.sh
fi

echo ""
echo "Start by deleting old environments which passed their shelf life"
echo ""

~/drupal-preprod/delete-old.sh

DIR=$PROJECT-$(echo $BRANCH|sed -e 's/\///g')-$HASH

echo "[info] Figure out a base directory name: $DIR"
echo "[info] About to attempt to create environments"

REPO=$(git config --get remote.origin.url)

echo "[info] Repo is $REPO"

~/drupal-preprod/fetch-branch.sh -d "$(pwd -P)" -r "$REPO" -b "$BRANCH" -h "$HASH" -p $PROJECT -z $DELETE

echo ""
echo "If ./scripts/deploy/drupal-preprod-setup.sh exists in your project, calling"
echo "it now; You should put any commands there which might be necessary to run"
echo "your Drupal site, for example setting up symlinks between sites/default and"
echo "sites/foo if you are using multisite."
echo ""
echo "If you do use ./scripts/deploy/drupal-preprod-setup.sh, make sure you cd"
echo "into each environment (new and preprod), for example:"
echo "cd $DIR/new && DO SOMETHING && cd ../.."
echo "cd $DIR/preprod && DO SOMETHING && cd ../.."
echo ""

if [ -a ./scripts/deploy/drupal-preprod-setup.sh ]
  then
    ./scripts/deploy/drupal-preprod-setup.sh
    echo ""
    echo "./scripts/deploy/drupal-preprod-setup.sh exists and was called."
    echo ""
  else
    echo ""
    echo "./scripts/deploy/drupal-preprod-setup.sh does not exist in $(pwd)."
    echo ""
fi

echo ""
echo "Build a new site"
echo ""

if [ -a ./scripts/deploy/drupal-preprod-info.sh ]
  then
    source ./scripts/deploy/drupal-preprod-info.sh
    if [ -n "$DEPLOYMODULES" ]
      then
        ~/drupal-preprod/deploy-new.sh -d $DIR/new -m $DEPLOYMODULES
      else
        echo -e "\nUnable to build a new site without cloning the database;"
        echo -e "please add 'DEPLOYMODULES=\"mysite_deploy mysite_devel\"'"
        echo -e "to the file DRUPAL_ROOT/scripts/deploy/drupal-preprod-info.sh"
        echo -e "so I can know which modules you want to enable. See also"
        echo -e "http://dcycleproject.org/blog/44/what-site-deployment-module\n"
    fi
fi

echo "[info] About to attempt to build the preprod site"

if [ -n "$DB" ]
  then
    ~/drupal-preprod/deploy-preprod.sh -d $DIR/preprod -f $FILES -b $DB
  if [ -c ./scripts/deploy/drupal-preprod-post-deploy.sh ]
    then
      ./scripts/deploy/drupal-preprod-post-deploy.sh
    else
      echo -e "[info] ./scripts/deploy/drupal-preprod-post-deploy.sh does not exist"
  else
    echo -e "[warning] Aborting: DB variable not set, please set it in ./scripts/deploy/drupal-preprod-info.sh"
fi

  cd $DIR/preprod && drush cc all && cd ../..
else
  echo "\nCannot deploy preproduction site, plus add a file called"
  echo "./scripts/deploy/drupal-preprod-info.sh in your Drupal project"
  echo "and add to it something like:"
  echo "FILES=https://example.com/myfiles.tar.gz"
  echo "DB=https://example.com/dbJ.sql.gz\n"
fi

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "preprod.sh end of script"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"
