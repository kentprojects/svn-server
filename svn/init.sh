# On recent upstart based Ubuntu versions you can place an upstart config file in /etc/init/svnserve.conf. See example svnserve.conf.
#
# svnserve - Subversion server
#

description "Subversion server"

start on (local-filesystems and net-device-up IFACE=lo and started udev-finish)
stop on runlevel [06]

chdir /home/svn

respawn

respawn limit 2 3600

exec /usr/bin/svnserve --daemon --foreground --root /home/svn/