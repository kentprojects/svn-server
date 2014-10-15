#!/bin/bash
# @category: Vagrant
# @author: James Dryden <jsd24@kent.ac.uk>
# @license: Copyright KentProjects
# @link: http://kentprojects.com

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
	if [ ! -d "/home/svn/$1" ]; then
		echo "Repository does not exist at /home/svn/$1"
		return 2;
	fi

	echo "$2 = h3r0" >> "/home/svn/$URL/conf/passwd.ini"
	sudo -u trac trac-admin "/home/trac/$URL" permission add "$2" developer
	sudo -u trac trac-admin "/home/trac/$URL" deploy /home/trac/$URL/deploy
	chmod 0775 -R "/home/trac/$URL"
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

	sudo -u trac trac-admin "/home/trac/$URL" deploy "/home/trac/$URL/deploy"
	chmod 0775 -R "/home/trac/$URL"
}