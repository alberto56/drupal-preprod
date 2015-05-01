echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "preprod.sh"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"

PROJECT=$1
BRANCH=$2
DELETE=$3

echo -e "[info] Project is $PROJECT"
echo -e "[info] Branch is $BRANCH"
echo -e "[info] Project set to be deleted in $DELETE day(s)"

if [ -z $PROJECT ]
  then
    echo -e "[error] Exiting: you must specify the project.\n"
    exit 1
fi
if [ -z $BRANCH ]
  then
    echo -e "[error] Exiting: you must specify the branch.\n"
    exit 1
fi
if [ -z $DELETE ]
  then
    echo -e "[error] Exiting: you must specify the number of days to keep this live even if it's zero (0).\n"
    exit 1
fi

HASH=$(git log -n1 --pretty='%h')

if [ -c ./scripts/deploy/drupal-preprod-info.sh ]
  then
    source ./scripts/deploy/drupal-preprod-info.sh
fi

echo "[info] Start by deleting old environments which passed their shelf life"

~/drupal-preprod/delete-old.sh

DIR=$PROJECT-$(echo $BRANCH|sed -e 's/\///g')-$HASH

echo "[info] Figure out a base directory name: $DIR"
echo "[info] About to attempt to create environments"

REPO=$(git config --get remote.origin.url)

echo "[info] Repo is $REPO"

~/drupal-preprod/fetch-branch.sh -d "$(pwd -P)" -r "$REPO" -b "$BRANCH" -h "$HASH" -p $PROJECT -z $DELETE

echo "[info] If ./scripts/deploy/drupal-preprod-setup.sh exists in your project, calling"
echo "       it now; You should put any commands there which might be necessary to run"
echo "       your Drupal site, for example setting up symlinks between sites/default and"
echo "       sites/foo if you are using multisite."
echo ""
echo "       If you do use ./scripts/deploy/drupal-preprod-setup.sh, make sure you cd"
echo "       into each environment (new and preprod), for example:"
echo "       cd "'$1'"/new && DO SOMETHING && cd ../.."
echo "       cd "'$1'"/preprod && DO SOMETHING && cd ../.."

if [ -a ./scripts/deploy/drupal-preprod-setup.sh ]
  then
    ./scripts/deploy/drupal-preprod-setup.sh $DIR
    echo "[info] ./scripts/deploy/drupal-preprod-setup.sh exists and was called with the argument $DIR."
  else
    echo "[info] ./scripts/deploy/drupal-preprod-setup.sh does not exist in $(pwd)."
fi

echo "[info] Build a new site"

if [ -a ./scripts/deploy/drupal-preprod-info.sh ]
  then
    source ./scripts/deploy/drupal-preprod-info.sh
    if [ -n "$DEPLOYMODULES" ]
      then
        ~/drupal-preprod/deploy-new.sh -d $DIR/new -m "$DEPLOYMODULES"
      else
        echo -e "[warning] Unable to build a new site without cloning the database;"
        echo -e "          please add 'DEPLOYMODULES=\"mysite_deploy mysite_devel\"'"
        echo -e "          to the file DRUPAL_ROOT/scripts/deploy/drupal-preprod-info.sh"
        echo -e "          so I can know which modules you want to enable. See also"
        echo -e "          http://dcycleproject.org/blog/44/what-site-deployment-module\n"
    fi
fi

echo "[info] About to attempt to build the preprod site"

if [ -n "$DB" ]
  then
    ~/drupal-preprod/deploy-preprod.sh -r "$BRANCH" -p "$PROJECT" -h "$HASH" -d $DIR/preprod -f $FILES -b $DB
    if [ -e ./scripts/deploy/drupal-preprod-post-deploy.sh ]
      then
        echo -e "[info] $(pwd)/scripts/deploy/drupal-preprod-post-deploy.sh does exist and will be run now"
        ./scripts/deploy/drupal-preprod-post-deploy.sh "$DIR"
      else
        echo -e "[info] $(pwd)/scripts/deploy/drupal-preprod-post-deploy.sh does not exist"
    fi

    cd $DIR/preprod && drush cc all && cd ../..
  else
    echo -e "[warning] Cannot deploy preproduction site, please add a file called"
    echo -e "          ./scripts/deploy/drupal-preprod-info.sh in your Drupal project"
    echo -e "          and add to it something like:"
    echo -e "          FILES=https://example.com/myfiles.tar.gz"
    echo -e "          DB=https://example.com/dbJ.sql.gz"
fi

echo -e "\n* * * * * * * * * * * * * * * * * * * * * * * * "
echo -e "preprod.sh end of script"
echo -e "* * * * * * * * * * * * * * * * * * * * * * * * \n"
