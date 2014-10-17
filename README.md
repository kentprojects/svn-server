# KentProjects SVN Server

The KentProjects SVN Server is a simple NodeJS application that allows direct manipulation of SVN repositories via a simple HTTP API.
Written in NodeJS so that the server this runs on will only be running:

- [NodeJS](http://nodejs.org) (& [NPM](https://www.npmjs.org))
- [SVN](https://subversion.apache.org)
- [Trac](http://trac.edgewall.org) (& [Apache](http://httpd.apache.org))

**No [PHP](http://php.net)!**

## Introduction

The purpose of this SVN server is to simulate a service where an institute running an SVN server
and requires repositories to be created and destroyed on demand.

## Installation

Check out the [Vagrant provisioning script](./Vagrantprovision.sh), which executes whenever we build a new Vagrant box from scratch.
It contains all the packages and all the various permission changes and symlinks which are required when building a relatively complex system.
Saying that, it's not relatively complex. It was to setup. But from this angle it seems relatively simple!

## Documentation

Here is a list of endpoints & methods that this API supports.

### Get a list of all repositories

```http
GET /repos HTTP/1.1
Host: svnadmin.kentprojects.com
```

A simple `GET` request to fetch a list of all the active repositories!

```json
[
	"2014/KettleProject",
	"2014/FlyingMachineProject"
]
```

### Create repositories

```http
POST /repo HTTP/1.1
Host: svnadmin.kentprojects.com
```

```json
{
	"name": "KettleProject"
}
```

A simple `POST` request to create a new repository!

If the project already exists (for this year) then you will get back:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
```

```json
{
	"error": true,
	"message": "This repository (2014/KettleProject) already exists.",
	"reason": "already_exists"
}
```

If the project doesn't exist, it will be created and the new repository data will be returned to you:

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
	"name": "KettleProject",
	"repository": "code.kentprojects.com/2014/KettleProject"
}
```

### Get repository data

```http
GET /repo/2014/KettleProject HTTP/1.1
Host: svnadmin.kentprojects.com
```

Which will return you information about that project:

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
	"name": "KettleProject",
	"repository": "code.kentprojects.com/2014/KettleProject",
	"users": [
		"jsd24", "mh472", "mjw59"
	],
	"recent": [
		{
			"author": "Matt Weeks <mjw59@kent.ac.uk>",
			"message": "Updates!"
		},
		{
			"author": "James D <james@jdrydn.com>",
			"message": "Initial commit"
		}
	]
}
```

### Add user to repository

TBA.

### Remove user from repository

TBA.

## Contact

For more information, contact any of us developers individually on [Github](/kentprojects) or collectively at <developer@kentprojects.com>.