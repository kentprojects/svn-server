#!/usr/bin/env bash
# @category: Vagrant
# @author: James Dryden <jsd24@kent.ac.uk>
# @license: Copyright KentProjects
# @link: http://kentprojects.com
locale-gen en_GB.UTF-8
# Ensure the apt-get service is up to date!
apt-get update
# Install the first wave of packages (Apache with WSGI & Perl mods).
aptitude install -y apache2 apache2.2-common apache2-mpm-prefork apache2-utils libexpat1 ssl-cert
aptitude install -y libapache2-mod-wsgi libapache2-mod-perl2 libapache2-mod-svn
service apache2 restart
# Install the second wave of packages (SVN, NodeJS, SQLite & various Python tools).
apt-get install -y subversion nodejs sqlite3 python-subversion python-sqlite
# Install the third wave of packages (Trac).
apt-get install -y trac trac-mastertickets trac-wysiwyg trac-wikitablemacro trac-tags trac-customfieldadmin trac-datefieldplugin
# apt-get install -y trac-accountmanager trac-graphviz trac-icalviewplugin
# Remove any unnecessary packages.
apt-get autoremove -y

# Directories required for the SVN server.
mkdir /home/svn /home/trac
# Set /home/node to be our project root.
ln -s /vagrant /home/server
# Set a symlink to the common /usr/share folder.
ln -s /usr/lib/python2.7/dist-packages/trac /usr/share/trac

# Create a user for SVN
adduser --system --shell /bin/sh --gecos 'SVN Project Managment' --group --disabled-password --home /home/svn subversion
adduser www-data subversion
adduser vagrant subversion
# Create a user for Trac
adduser --system --shell /bin/sh --gecos 'Trac Project Managment' --group --disabled-password --home /home/trac trac
adduser www-data trac
adduser vagrant trac

# Fix permissions
chown www-data:subversion /home/svn
chown www-data:trac /home/trac
chmod -R g+rws /home/svn
chmod 0775 -R /home/trac

# sudo -u www-data svnserve --daemon --root /home/svn

service apache2 stop
# a2enmod rewrite
rm /etc/apache2/mods-enabled/dav_svn.conf
ln -s /home/server/svn/dav_svn.conf /etc/apache2/mods-enabled/dav_svn.conf
rm /etc/apache2/sites-enabled/*
ln -s /home/server/apache.10.conf /etc/apache2/sites-enabled/10-Server.conf
ln -s /home/server/apache.20.conf /etc/apache2/sites-enabled/20-SVN-Server.conf
service apache2 restart

NAME="KettleProject"
URL=$(date +"%Y")"/$NAME"

echo "Creating an example repository named $URL"

SVNBASE="/home/svn/$URL"
TRACBASE="/home/trac/$URL"

# Create the Subversion Repository
sudo -u subversion mkdir "$SVNBASE" -p
sudo -u subversion svnadmin create "$SVNBASE"
sudo -u subversion cp /home/server/svn/svnserve.conf "$SVNBASE/conf/svnserve.conf"
sudo -u subversion cp /home/server/svn/passwd.ini "$SVNBASE/conf/passwd"
echo "james = h3r0" >> "$SVNBASE/conf/passwd"
chmod 0775 -R "$SVNBASE"

# Create the Trac instance
sudo -u trac mkdir "$TRACBASE" -p
sudo -u trac trac-admin "$TRACBASE" initenv "$NAME" "sqlite:db/trac.db"
sudo -u trac trac-admin "$TRACBASE" repository add "$NAME" "$SVNBASE"

sudo -u trac trac-admin "$TRACBASE" permission add admin TRAC_ADMIN
sudo -u trac trac-admin "$TRACBASE" permission add developer BROWSER_VIEW CHANGESET_VIEW FILE_VIEW LOG_VIEW MILESTONE_ADMIN REPORT_ADMIN SEARCH_VIEW TICKET_ADMIN TIMELINE_VIEW WIKI_ADMIN

sudo -u trac trac-admin "$TRACBASE" permission add "james" developer

sudo -u trac trac-admin "$TRACBASE" deploy "$TRACBASE/deploy"
chmod 0775 -R "$TRACBASE"

sudo service apache2 restart