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

#### Request

```http
GET / HTTP/1.1
Host: code.kentprojects.com
```

#### Response

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
[
	"2014/KettleProject",
	"2014/FlyingMachineProject"
]
```

### Create repositories

#### Request

```http
POST / HTTP/1.1
Host: code.kentprojects.com
```

```json
{
	"name": "KettleProject"
}
```

#### Response

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
	"name": "2014/KettleProject",
	"svn": "svn://code.kentprojects.com/2014/KettleProject",
	"trac": "http://code.kentprojects.com/2014/KettleProject"
}
```

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

### Delete a repository

#### Request

```http
POST /api/2014/KettleProject/delete HTTP/1.1
Host: code.kentprojects.com
```

#### Response

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
"Repository 2014/KettleProject deleted."
```

### Add user to repository

```http
POST /api/:YEAR/:REPOSITORY/user HTTP/1.1
Host: code.kentprojects.com
```

#### Request

```http
POST /api/2014/KettleProject/user HTTP/1.1
Host: code.kentprojects.com
```

```json
{
  "jsd24": "somepassword1",
  "mh472": "somepassword2",
  "mjw43": "somepassword3"
}
```

#### Response

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
"Users jsd24,mh472,mjw43 added to 2014/KettleProject"
```

### Remove user from repository

```http
POST /api/:YEAR/:REPOSITORY/delete/:USER HTTP/1.1
Host: code.kentprojects.com
```

#### Request

```http
POST /api/2014/KettleProject/delete/mh472 HTTP/1.1
Host: code.kentprojects.com
```

#### Response

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
"User mh472 deleted from 2014/KettleProject"
```

## Contact

For more information, contact any of us developers individually on [Github](/kentprojects) or collectively at <developer@kentprojects.com>.