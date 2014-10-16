#!/bin/bash
# @category: Vagrant
# @author: James Dryden <jsd24@kent.ac.uk>
# @license: Copyright KentProjects
# @link: http://kentprojects.com

sudo true

#
# Add a new user to a repository.
#
# @param string $1 The repository name
# @param string $1 The user name
# @return void
#
function AddUserToRepository
{
	if [ -z "$1" ]; then
		echo "Please supply a repository name to AddUserToRepository"
		return 1;
	fi
	if [ -z "$2" ]; then
		echo "Please supply a user name to AddUserToRepository"
		return 1;
	fi

	SVNBASE="/home/svn/$1"
	TRACBASE="/home/trac/$1"

	if [ ! -d "$SVNBASE" ]; then
		echo "Repository does not exist at $SVNBASE"
		return 2;
	fi

	echo "$2 = h3r0" >> "$SVNBASE/conf/passwd"
	sudo -u trac trac-admin "$TRACBASE" permission add "$2" developer
	sudo -u trac trac-admin "$TRACBASE" deploy "$TRACBASE/deploy"
	chmod 0775 -R "$SVNBASE"
	chmod 0775 -R "$TRACBASE"
}

#
# Creates a new repository.
#
# @param string $1 The new repository name
# @return void
#
function CreateRepository
{
	if [ -z "$1" ]; then
		echo "Please supply a repository name to CreateRepository"
		return 1;
	fi

	NAME="$1"
	URL=$(date +"%Y")"/$NAME"

	SVNBASE="/home/svn/$URL"
	TRACBASE="/home/trac/$URL"

	# Create the Subversion Repository
	sudo -u subversion mkdir "$SVNBASE" -p
	sudo -u subversion svnadmin create "$SVNBASE"
	sudo -u subversion cp /home/server/svn/svnserve.conf "$SVNBASE/conf/svnserve.conf"
	sudo -u subversion cp /home/server/svn/passwd.ini "$SVNBASE/conf/passwd"
	chmod 0775 -R "$SVNBASE"

	# Create the Trac instance
	sudo -u trac mkdir "$TRACBASE" -p
	sudo -u trac trac-admin "$TRACBASE" initenv "$NAME" "sqlite:db/trac.db"
	sudo -u trac trac-admin "$TRACBASE" repository add "$NAME" "$SVNBASE"

	sudo -u trac trac-admin "$TRACBASE" permission add admin TRAC_ADMIN
	sudo -u trac trac-admin "$TRACBASE" permission add developer BROWSER_VIEW CHANGESET_VIEW FILE_VIEW LOG_VIEW MILESTONE_ADMIN REPORT_ADMIN SEARCH_VIEW TICKET_ADMIN TIMELINE_VIEW WIKI_ADMIN

	sudo -u trac trac-admin "$TRACBASE" deploy "$TRACBASE/deploy"
	chmod 0775 -R "$TRACBASE"

	sudo service apache2 restart
}