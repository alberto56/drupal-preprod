FROM dockerfiles/centos-lamp
MAINTAINER @alberto56

RUN /sbin/service mysqld start

RUN mkdir -p /path/to/my/workspace/should-not-be-deleted
RUN mkdir -p /path/to/my/workspace/should-be-deleted
RUN mkdir -p /path/to/my/workspace/should-eventually-be-deleted

RUN echo '0' >> /path/to/my/workspace/should-be-deleted/delete.txt
RUN echo '999999999999999' >> /path/to/my/workspace/should-eventually-be-deleted/delete.txt

ADD . /drupal-preprod/
RUN cp /drupal-preprod/example.drupal-preprod.variables ~/.drupal-preprod.variables

#RUN cd /path/to/my/workspace && ~/drupal-preprod/delete-old.sh

#RUN if [ -d /path/to/my/workspace/should-be-deleted ]; then echo "/path/to/my/workspace/should-be-deleted should not exist"; exit 1; fi
