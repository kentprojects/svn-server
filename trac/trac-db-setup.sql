/**
 * @category: SVN-Server
 * @author: James Dryden <jsd24@kent.ac.uk>
 * @license: Copyright KentProjects
 * @link: http://www.kentprojects.com
 */

CREATE DATABASE `trac` DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
GRANT ALL ON `trac`.* TO tracuser@localhost IDENTIFIED BY 'password';