Drupal Preprod
=====

This collection of scripts is meant to be put on a Jenkins box, to deploy preproduction versions of any branch on any project.

Project homepage and issue queue
-----

[The project lives on GitHub](https://github.com/alberto56/drupal-preprod).

How it works
-----

This is meant to be used with parametrizable Jenkins builds. You select a project, a branch and delete date, and then use these scripts to grab the code, and create two environments:

 * The first [does not clone the database](http://dcycleproject.org/blog/48/do-not-clone-database), using instead a [site deployment module](http://dcycleproject.org/blog/44/what-site-deployment-module) and runs `drush generate-content` to generate realistic-looking dummy content with the [Drupal realistic dummy content module](https://www.drupal.org/project/realistic_dummy_content).
 * The second grabs a database and the files from a predetermined source, create a real clone of production (or any other environment you choose).

The current version of this script does not use Vagrant or Docker to run environments. You need a LAMP stack on your Jenkins box.

Getting started
-----

 * Install a Jenkins box, for example [vagrant-jenkins](https://github.com/alberto56/vagrant-jenkins)
 * Make sure your `jenkins` user has access to restart apache and can modify ` /var/lib/jenkins/conf.d/` and `/etc/host`. You can use `visudo` and linux groups for that (ask someone who knows Linux).
 * Switch users so you are jenkins (`sudo su -s /bin/bash jenkins`)
 * Start by putting `drupal-preprod` at `~/drupal-preprod`.
 * Create a Jenkins job at `/path/to/job`.
 * Create a virtual host entry so that `/path/to/job/drupal-preprod-index/index.html` exists and is accessible through the web at http://drupal-preprod.example.com/
 * Make sure you have some sort of authentication or VPN to avoid the public seeing your sites, because they may contain sensitive data.
 * Setup wildcard subdomains which point to your Jenkins box.

Set your local information:

At `~/.drupal-preprod.variables`, put the following info:

    cp ~/drupal-preprod/example.drupal-preprod.variables ~/drupal-preprod.variables

Then put whatever your local information is in there (MySQL password, etc.).

Create a job
-----

Make your job a parametrizable build with:

 * DELETE = number of days you want your environment to live
 * BRANCH = the branch of your environment.
 * PROJECT = the project name.

Your job's build script should be:

    ~/drupal-preprod/preprod.sh $PROJECT $BRANCH $DELETE

Run your first job
-----

When you run your job, previous jobs which have outlived their shelf life will be deleted.

You can now run your job, and when you hit http://drupal-preprod.example.com, you will see a list of all your environments.

Logging into temporary environments
-----

Create a new parametrizable Jenkins job which takes a parameter called COMMIT, and then make sure the build script is:

    ~/drupal-preprod/uli.sh $COMMIT

Running this will give you login information for all your environments which have that commit number.

Testing and continuous integration
-----

Limited tests are provided, using a Dockerfile. To test this, you can

 * Create a [Vagrant CoreOS VM](https://github.com/coreos/coreos-vagrant) on your laptop.
 * Put this project on your VM and navigate to it.
 * Type `./test.sh` from within this folder.

The above will install CentoOS, a LAMP stack, and run a few tests.

Tests are also run continuously with the excellent free [CircleCI](https://circleci.com) continuous integration service.

Here is the current state of this project:

[![Circle CI](https://circleci.com/gh/alberto56/drupal-preprod/tree/master.svg?style=svg)](https://circleci.com/gh/alberto56/drupal-preprod/tree/master)
