PROJECT=$1
BRANCH=$2
DELETE$3

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

echo ""
echo "Figure out a base directory name: $DIR"
echo ""

echo ""
echo "Create the environments"
echo ""

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

echo ""
echo "Build the preprod site"
echo ""

if [ -n "$DB" ]
  then
    ~/drupal-preprod/deploy-preprod.sh -d $DIR/preprod -f $FILES -b $DB
  if [ -c ./scripts/deploy/drupal-preprod-post-deploy.sh ]
    then
      ./scripts/deploy/drupal-preprod-post-deploy.sh
fi

  cd $DIR/preprod && drush cc all && cd ../..
else
  echo ""
  echo "Cannot deploy preproduction site, plus add a file called"
  echo "./scripts/deploy/drupal-preprod-info.sh in your Drupal project"
  echo "and add to it something like:"
  echo "FILES=https://example.com/myfiles.tar.gz"
  echo "DB=https://example.com/dbJ.sql.gz"
  echo ""
fi
