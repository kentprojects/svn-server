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
aptitude install -y libapache2-mod-wsgi libapache2-mod-perl2
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
# Set a symlink to the common /usr/share folder.
ln -s /usr/lib/python2.7/dist-package/trac /usr/share/trac

# Create a Trac user
adduser --system --shell /bin/sh --gecos 'Trac Project Managment' --group --disabled-password --home /home/trac trac
# Allow Apache to access Trac files
adduser www-data trac

# Fix permissions
chown www-data:www-data /home/svn
chown www-data:trac /home/trac
chmod -R g+rws /home/svn
chmod 0775 -R /home/trac

sudo -u www-data svnserve --daemon --root /home/svn

service apache2 stop
a2enmod rewrite
rm /etc/apache2/sites-enabled/*
ln -s /home/server/apache.conf /etc/apache2/sites-enabled/10-SVN-Server.conf
service apache2 start

echo "Creating an example repository named 2014-KettleProject"

NAME="KettleProject"
URL=$(date +"%Y")"/$NAME"

# Create the Subversion Repository
sudo -u www-data mkdir "/home/svn/$URL" -p
sudo -u www-data svnadmin create "/home/svn/$URL"
sudo -u www-data cp /home/server/svn/svnserve.conf "/home/svn/$URL/conf/svnserve.conf"
sudo -u www-data cp /home/server/svn/passwd.ini "/home/svn/$URL/conf/passwd.ini"

# Create the Trac instance
sudo -u trac mkdir "/home/trac/$URL" -p
sudo -u trac trac-admin "/home/trac/$URL" initenv "$NAME" "sqlite:db/trac.db"
sudo -u trac trac-admin "/home/trac/$URL" repository add "$NAME" "/home/svn/$URL"

sudo -u trac trac-admin "/home/trac/$URL" permission add admin TRAC_ADMIN
sudo -u trac trac-admin "/home/trac/$URL" permission add developer BROWSER_VIEW CHANGESET_VIEW FILE_VIEW LOG_VIEW MILESTONE_ADMIN REPORT_ADMIN SEARCH_VIEW TICKET_ADMIN TIMELINE_VIEW WIKI_ADMIN

echo 'james = h3r0' >> "/home/svn/$URL/conf/passwd.ini"
sudo -u trac trac-admin "/home/trac/$URL" permission add "james" developer

sudo -u trac trac-admin "/home/trac/$URL" deploy "/home/trac/$URL/deploy"
chmod 0775 -R "/home/trac/$URL"