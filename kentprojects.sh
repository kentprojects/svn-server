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
	if [ -z "$3" ]; then
		echo "Please supply a password to AddUserToRepository"
		return 1;
	fi

	SVNBASE="/home/svn/$1"
	TRACBASE="/home/trac/$1"

	if [ ! -d "$SVNBASE" ]; then
		echo "Repository does not exist at $SVNBASE"
		return 2;
	fi

	cat << EOL | sudo tee -a "$SVNBASE/conf/passwd"
$2 = $3
EOL
	sudo -u trac htpasswd -b "$TRACBASE/conf/passwd" "$2" "$3"
	sudo -u trac trac-admin "$TRACBASE" permission add "$2" developer

	sudo -u trac trac-admin "$TRACBASE" deploy "$TRACBASE/deploy"
	sudo chmod 775 -R "$SVNBASE"
	sudo chmod 775 -R "$TRACBASE"
	sudo chmod 777 -R "$TRACBASE/db"
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

	sudo -u subversion cp /home/server/svn/passwd.ini "$SVNBASE/conf/passwd"
	cat << EOL | sudo tee "$SVNBASE/conf/svnserve.conf"
[general]
anon-access = none
auth-access = write
realm = $URL
password-db = passwd
EOL
	sudo chmod 775 -R "$SVNBASE"

	# Create the Trac instance
	sudo -u trac mkdir "$TRACBASE" -p
	sudo -u trac trac-admin "$TRACBASE" initenv "$NAME" "sqlite:db/trac.db"
	sudo chmod 777 -R "$TRACBASE/db"
	sudo -u trac cp /home/server/trac/passwd "$TRACBASE/conf/passwd"

	# Trac permissions
	sudo -u trac trac-admin "$TRACBASE" permission remove anonymous "*"
	sudo -u trac trac-admin "$TRACBASE" permission add anonymous WIKI_VIEW
	sudo -u trac trac-admin "$TRACBASE" permission add admin BROWSER_VIEW CHANGESET_VIEW FILE_VIEW LOG_VIEW TRAC_ADMIN
	sudo -u trac trac-admin "$TRACBASE" permission add developer BROWSER_VIEW CHANGESET_VIEW FILE_VIEW LOG_VIEW MILESTONE_ADMIN REPORT_ADMIN SEARCH_VIEW TICKET_ADMIN TIMELINE_VIEW WIKI_ADMIN

	sudo touch "$SVNBASE/hooks/post-commit"
	cat << EOL | sudo tee -a "$SVNBASE/hooks/post-commit"
#!/bin/sh
export PYTHON_EGG_CACHE="/tmp/pythoneggs"
/usr/bin/trac-admin $TRACBASE changeset added "\$1" "\$2"
EOL
	sudo chmod 755 "$SVNBASE/hooks/post-commit"

	sudo touch "$SVNBASE/hooks/post-revprop-change"
	cat << EOL | sudo tee -a "$SVNBASE/hooks/post-revprop-change"
#!/bin/sh
export PYTHON_EGG_CACHE="/tmp/pythoneggs"
/usr/bin/trac-admin $TRACBASE changeset modified "\$1" "\$2"
EOL
	sudo chmod 755 "$SVNBASE/hooks/post-revprop-change"

	cat << EOL | sudo tee -a "$TRACBASE/conf/trac.ini"
[components]
tracopt.versioncontrol.svn.* = enabled
EOL

	sudo -u trac trac-admin "$TRACBASE" repository add "$NAME" "$SVNBASE" svn
	sudo -u trac trac-admin "$TRACBASE" repository set "$NAME" "url" "http://code.kentprojects.com/$URL"

	# Trac deploy
	sudo -u trac trac-admin "$TRACBASE" deploy "$TRACBASE/deploy"
	sudo chmod 775 -R "$TRACBASE"
	sudo chmod 777 -R "$TRACBASE/db"

	sudo service apache2 restart
	sudo svn import /home/server/svn/default "file://$SVNBASE" -m "Initial import of the structure."
}

#
# Deletes a repository.
#
# @param string $1 The new repository name
# @return void
#
function DeleteRepository
{
	if [ -z "$1" ]; then
		echo "Please supply a repository name to DeleteRepository"
		return 1;
	fi

	if [ -d "/home/svn/$1" ]; then
		sudo rm -r "/home/svn/$1"
		echo "SVN repository for $1 has been deleted."
	fi

	if [ -d "/home/trac/$1" ]; then
		sudo rm -r "/home/trac/$1"
		echo "Trac instance for $1 has been deleted."
	fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	case "$1" in
		"CreateRepository") shift; CreateRepository $@ ;;
		"AddUserToRepository") shift; AddUserToRepository $@ ;;
		"DeleteRepository") shift; DeleteRepository $@ ;;
	esac
fi