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

~/delete-old.sh

DIR=$PROJECT-$(echo $BRANCH|sed -e 's/\///g')-$HASH

echo ""
echo "Figure out a base directory name: $DIR"
echo ""

echo ""
echo "Create the environments"
echo ""

~/fetch-branch.sh -d "$(pwd -P)" -r "$REPO" -b "$BRANCH" -h "$HASH" -p $PROJECT -z $DELETE

echo ""
echo "Set symlinks to sites/default correctly"
echo ""

if [ -c ./scripts/deploy/drupal-preprod-setup.sh ]
  then
    ./scripts/deploy/drupal-preprod-setup.sh
fi

echo ""
echo "Build a new site"
echo ""

if [ -c ./scripts/deploy/drupal-preprod-info.sh ]
  then
    source ./scripts/deploy/drupal-preprod-info.sh
    ~/deploy-new.sh -d $DIR/new -m $DEPLOYMODULES
fi

echo ""
echo "Build the preprod site"
echo ""

if [ -n "$DB" ]
  then
    ~/deploy-preprod.sh -d $DIR/preprod -f $FILES -b $DB
else
  echo ""
  echo "Cannot deploy preproduction site, plus add a file called"
  echo "./scripts/deploy/drupal-preprod-info.sh in your Drupal project"
  echo "and add to it something like:"
  echo "FILES=https://example.com/myfiles.tar.gz"
  echo "DB=https://example.com/db.sql.gz"
  echo ""
fi



if [ -c ./scripts/deploy/drupal-preprod-post-deploy.sh ]
  then
    ./scripts/deploy/drupal-preprod-post-deploy.sh
fi

cd $DIR/preprod && drush cc all && cd ../..
