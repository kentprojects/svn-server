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
aptitude install -y libapache2-mod-wsgi libapache2-mod-perl2
service apache2 restart
# Install the next wave of packages (SVN, NodeJS, NPM, SQLite & various Python tools).
apt-get install -y subversion nodejs npm sqlite3 python-subversion python-sqlite
# Install the final wave of packages (Trac).
apt-get install -y trac trac-mastertickets trac-wysiwyg trac-wikitablemacro trac-tags trac-customfieldadmin trac-datefieldplugin
# apt-get install -y trac-accountmanager trac-graphviz trac-icalviewplugin
# Remove any unnecessary packages.
apt-get autoremove -y

# Directories required for the SVN server.
mkdir /home/svn /home/trac /home/node
# Set /home/server to be our project root.
ln -s /vagrant /home/server
# Set a symlink to the common /usr/sshare folder.
ln -s /usr/lib/python2.7/dist-packages/trac /usr/share/trac
# Set a symlink to the executable.
ln -s /home/server/kentprojects.sh /bin/kentprojects
chmod +x /bin/kentprojects

# Somewhere for the PythonEggs to live!
mkdir -p /tmp/pythoneggs
chown www-data:www-data /tmp/pythoneggs
chmod 777 /tmp/pythoneggs

# Setup a SVN user and set the relevant permissions!
adduser --system --shell /bin/sh --gecos 'SVN Project Managment' --group --disabled-password --home /home/svn subversion
adduser www-data subversion
adduser vagrant subversion
chown subversion:subversion /home/svn
chmod -R g+rws /home/svn
# Setup a Trac user and set the relevant permissions!
adduser --system --shell /bin/sh --gecos 'Trac Project Managment' --group --disabled-password --home /home/trac trac
adduser subversion trac
adduser www-data trac
adduser vagrant trac
chown trac:trac /home/trac
chmod 775 -R /home/trac
# Get the NodeJS API ready for install.
cp /home/server/node/* /home/node
chown -R vagrant:vagrant /home/node

# Start the SVN Server
sudo -u subversion svnserve --daemon --root /home/svn
# Set the SVN Server to start on boot!
cp /vagrant/svn/init /etc/init.d/svnserve
chmod +x /etc/init.d/svnserve
update-rc.d svnserve defaults

# Configure the Apache server
service apache2 stop
a2enmod proxy_http
rm /etc/apache2/sites-enabled/*
ln -s /home/server/apache.10.conf /etc/apache2/sites-enabled/10-Server.conf
ln -s /home/server/apache.20.conf /etc/apache2/sites-enabled/20-SVN-Server.conf
service apache2 restart

# To assist in examples, let's quickly create a pretend project.
echo "Creating an example project at 2014/KettleProject"
kentprojects CreateRepository "KettleProject"
kentprojects AddUserToRepository "2014/KettleProject" "james" "password"