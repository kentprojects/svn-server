/**
 * @category: SVN-Server
 * @author: James Dryden <jsd24@kent.ac.uk>
 * @license: Copyright KentProjects
 * @link: http://www.kentprojects.com
 */
require("shelljs/global");

var crypto = require("crypto"),
	express = require("express"),
	http = require("http"),
	moment = require("moment");

var authentication = require("./authentication.json"),
	config = {
		port: 4000,
		svn: {
			directory: "/home/svn",
			url: "svn://code.kentprojects.com/"
		},
		trac: {
			directory: "/home/trac",
			url: "http://code.kentprojects.com/"
		}
	},
	repositories = {},
	repositories_users = {};

/**
 * Used to authenticate the requests.
 *
 * @param request
 * @param response
 * @param next
 * @return void
 */
function Authenticate(request, response, next)
{
	if (!request.headers.token)
	{
		response.json(400, "Missing application token.");
		return;
	}

	for(var i = 0; i < authentication.length; i++)
	{
		if (authentication[i].key == request.headers.token)
		{
			request.application = authentication[i];
			next(); return;
		}
	}

	response.json(400, "Invalid application token.");
}
/**
 * The base look for a record.
 */
function BuildBasicRecord(name)
{
	return {
		name: name,
		svn: false,
		trac: false
	};
}
/**
 * Build the list from /home/svn.
 */
function BuildSVNlist(continuecallback)
{
	exec(
		"find /home/svn/*/* -maxdepth 0 -type d | awk '{print substr($0, 11)}'",
		{"async": true, "silent": true},
		function(code, output) {
			if (code > 0)
			{
				console.error(output);
				exit(1);
			}
			output.trim().split("\n").map(function(repository) {
				var record = repositories[repository] || BuildBasicRecord(repository);
				record.svn = config.svn.url + record.name;
				repositories[repository] = record;
			});
			continuecallback && continuecallback();
		}
	);
}
/**
 * Build the list from /home/trac.
 */
function BuildTraclist(continuecallback)
{
	exec(
		"find /home/trac/*/* -maxdepth 0 -type d | awk '{print substr($0, 12)}'",
		{"async": true, "silent": true},
		function(code, output) {
			if (code > 0)
			{
				console.error(output);
				exit(1);
			}
			output.trim().split("\n").map(function(repository) {
				var record = repositories[repository] || BuildBasicRecord(repository);
				record.trac = config.trac.url + record.name;
				repositories[repository] = record;
			});
			continuecallback && continuecallback();
		}
	);
}
function GetRepositoryUsers(repository)
{
	if (!repositories_users[repository])
	{
		repositories_users[repository] = exec(
			"cat /home/trac/"+repository+"/conf/passwd | cut -d ':' -f 1",
			{"async": false, "silent": true}
		).output.trim().split("\n");
		repositories_users[repository].shift();
	}
	return repositories_users[repository];
}
/**
 * Used to build a lovely list of repositories.
 * If we have a pre-built up-to-date list, then we don't have to continuous check the folders
 * on each request. Which is a nice plus.
 */
function UpdateListOfRepositories()
{
	BuildSVNlist(function() {
		BuildTraclist(function() {
			// console.log(list);
		});
	});
}

var app = express();

/**
 * If we're running this in production mode, then accept the proxy.
 * Because the proxy will be our own!
 */
app.configure(function() {
	app.enable('trust proxy');
});
app.configure("development", function() {
	app.disable('trust proxy');
	config.svn.url = "svn://localhost:8080/";
	config.trac.url = "http://localhost:8080/";
});

/**
 * Configure the API
 */
app.configure(function() {
	app.set("port", process.env.PORT || config.port);
	app.use(express.logger("dev"));
	app.use(express.favicon());
	app.use(express.json());
	app.use(Authenticate);
	app.use(app.router);
});
app.configure("development", function() {
	app.use(express.errorHandler());
});

/**
 * Get a list of the repositories.
 * GET /
 */
app.get("/", function(request, response) {
	response.json(200, repositories);
});
/**
 * Get a details of a specific repository.
 * GET /repo/:year/:name
 */
app.get("/:year/:name", function(request, response) {
	var url = request.params.year+"/"+request.params.name;
	if (!repositories[url])
	{
		response.json(400, "There isn't a repository at "+url);
		return;
	}
	var repository = repositories[url];
	repository.users = GetRepositoryUsers(url);
	response.json(200, repository);
});
/**
 * Creating a new repository.
 * POST /
 */
app.post("/", function(request, response) {
	if (!request.body.name)
	{
		response.json(400, "No name supplied to create a new repository.");
		return;
	}
	var url = moment().format("YYYY")+"/"+request.body.name;
	if (repositories[url])
	{
		response.json(400, "There is already a repository at "+repository.url);
		return;
	}
	exec(
		"kentprojects CreateRepository "+request.body.name,
		{ async: true, silent: true },
		function(code, output) {
			if (code != 0)
			{
				response.json(500, "There was an error creating the repository at "+url);
				return;
			}
			response.json(200, {
				name: request.body.name,
				svn: config.svn.url + url,
				trac: config.trac.url + url
			});
			UpdateListOfRepositories();
		}
	);
});
/**
 * Delete a repository.
 * POST /:year/:name/delete
 */
app.post("/:year/:name/delete", function(request, response) {
	var url = request.params.year+"/"+request.params.name;
	if (!repositories[url])
	{
		response.json(400, "There isn't a repository at "+url);
		return;
	}
	exec(
		"kentprojects DeleteRepository "+url,
		{ async: true, silent: true },
		function(code, output) {
			if (code != 0)
			{
				response.json(400, "There isn't a repository at "+url);
				return;
			}
			response.json(200, "Repository "+url+" deleted.");
			delete repositories[url];
			delete repositories_users[url];
		}
	);
});
/**
 * Add a user to the repository.
 * POST /:year/:name/user
 */
app.post("/:year/:name/user", function(request, response) {
	var url = request.params.year+"/"+request.params.name,
		users = [];
	if (!repositories[url])
	{
		response.json(400, "There isn't a repository at "+url);
		return;
	}
	if (typeof request.body !== "object")
	{
		response.json(400, "Request body is not an object.");
		return;
	}

	for(var user in request.body)
	{
		if (Object.prototype.hasOwnProperty.call(request.body, user))
		{
			users.push(user);
			exec(
				"kentprojects AddUserToRepository "+url+" "+user+" "+request.body[user],
				{ async: false, silent: true },
				function(code, output) {
					if (code != 0)
					{
						response.json(500, "There was an error adding the user "+user+" to the repository at "+url);
						return;
					}
				}
			);
		}
	}

	response.json(200, "Users "+users.join(",")+" added to "+url);
	UpdateListOfRepositories();
});
/**
 * Deletes a user from the repository.
 * POST /:year/:name/delete/:user
 */
app.post("/:year/:name/delete/:user", function(request, response) {
	var url = request.params.year+"/"+request.params.name;
	if (!repositories[url])
	{
		response.json(400, "There isn't a repository at "+url);
		return;
	}
	exec(
		"kentprojects RemoveUserFromRepository "+url+" "+request.params.user,
		{ async: true, silent: true },
		function(code, output) {
			if (code != 0)
			{
				response.json(500, "There was an error adding a user to the repository at "+url);
				return;
			}
			response.json(200, "User "+request.params.user+" deleted from "+url);
			delete repositories_users[url];
		}
	);
});

UpdateListOfRepositories();

http.createServer(app).listen(app.get("port"), function() {
	console.log("SVN Server listening on port " + app.get("port"));
});