#!/usr/bin/env bash
# @category: Vagrant
# @author: James Dryden <jsd24@kent.ac.uk>
# @license: Copyright KentProjects
# @link: http://kentprojects.com
locale-gen en_GB.UTF-8
# Ensure the apt-get service is up to date!
apt-get update
# Install the first wave of packages (Apache, SVN, NodeJS, SQLite & Python Tools).
aptitude install -y apache2 apache2.2-common apache2-mpm-prefork apache2-utils libexpat1 ssl-cert
aptitude install -y libapache2-mod-wsgi
service apache2 restart
apt-get install -y subversion nodejs sqlite3 python-subversion python-sqlite
# Install the second wave of packages (Trac).
apt-get install -y trac trac-mastertickets trac-wysiwyg trac-wikitablemacro trac-tags trac-customfieldadmin trac-datefieldplugin
# apt-get install -y trac-accountmanager trac-graphviz trac-icalviewplugin
# Remove any unnecessary packages.
apt-get autoremove -y

# Directories required for the SVN server.
mkdir /home/svn /home/trac
# Set /home/node to be our project root.
ln -s /vagrant /home/server

# Create a Trac user
adduser --system --shell /bin/sh --gecos 'Trac Project Managment' --group --disabled-password --home /home/trac trac
# Allow Apache to access Trac files
adduser www-data trac

# Fix permissions
chown www-data:trac /home/trac
chmod -R g+rws /home/svn
chmod 0775 -R /home/trac

svnserve --daemon --root /home/svn

service apache2 stop
a2enmod rewrite
rm /etc/apache2/sites-enabled/*
ln -s /home/server/apache.conf /etc/apache2/sites-enabled/10-SVN-Server.conf
service apache2 start

echo "Creating an example repository named 2014-KettleProject"

# Create an example SVN repository
mkdir /home/svn/2014/KettleProject -p
svnadmin create /home/svn/2014/KettleProject
cp /home/server/defaults/svnserve.conf /home/svn/2014/KettleProject/conf/svnserve.conf
cp /home/server/defaults/passwd.ini /home/svn/2014/KettleProject/conf/passwd.ini
# Create some example Trac projects
mkdir /home/trac/2014/KettleProject -p
sudo -u trac trac-admin /home/trac/2014/KettleProject initenv
sudo -u trac trac-admin /home/trac/2014/KettleProject deploy /home/trac/2014/KettleProject/deploy
chmod 0775 -R /home/trac