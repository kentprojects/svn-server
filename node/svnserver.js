/**
 * @category: SVN-Server
 * @author: James Dryden <jsd24@kent.ac.uk>
 * @license: Copyright KentProjects
 * @link: http://www.kentprojects.com
 */
require("shelljs/global");

var authentication = require("./authentication.json"),
	cmdOptions = {"async": false, "silent": true},
	express = require("express"),
	http = require("http"),
	list = {processed: [], svn: [], trac: []},

	app = express();

app.configure(function() {
	app.enable('trust proxy');
});

app.configure("development", function() {
	app.disable('trust proxy');
});

app.configure(function() {
	app.set("port", process.env.PORT || 4000);
	app.use(express.logger("dev"));
	app.use(express.favicon());
	app.use(express.json());
	app.use(express.urlencoded({limit: "10mb"}));
	app.use(app.router);
});

app.configure("development", function() {
	app.use(express.errorHandler());
});

/**
 * @param request
 * @param response
 * @param next
 * @return void
 */
function authenticate(request, response, next)
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
 * @param continuecallback
 * @return void
 */
function updateListOfRepositories(continuecallback)
{
	var buildSVNlist = function(continuecallback) {
		exec(
			"find /home/svn/*/* -maxdepth 0 -type d | awk '{print substr($0, 11)}'",
			{"async": true, "silent": true},
			function(code, output) {
				if (code > 0)
				{
					console.error(output);
					exit(1);
				}
				list.svn = output.trim().split("\n");
				list.svn.map(function(repository) {
					var record = list.processed[repository] || {};
					record.svn = true;
					list.processed[repository] = record;
				});
				continuecallback && continuecallback();
			}
		);
	};
	var buildTraclist = function(continuecallback) {
		exec(
			"find /home/trac/*/* -maxdepth 0 -type d | awk '{print substr($0, 12)}'",
			{"async": true, "silent": true},
			function(code, output) {
				if (code > 0)
				{
					console.error(output);
					exit(1);
				}
				list.trac = output.trim().split("\n");
				var record = list.processed[repository] || {};
				record.trac = true;
				list.processed[repository] = record;
				continuecallback && continuecallback();
			}
		);
	};

	buildSVNlist(function() {
		buildTraclist(continuecallback);
	});
}

/**
 * @return boolean
 */
function ifDirectoryExists(directory)
{
	return exec('[ -d "'+directory+'" ] && echo "true"', cmdOptions).output.trim() === "true";
}

app.get("/", function(request, response) {
	response.status(200);
	response.json("Welcome to the SVN Server!");
});
app.get("/repos", authenticate, function(request, response) {
	if (list.processed.length === 0)
	{
		response.json(400, "No repositories.");
		return;
	}
	response.json(200, list);
});
app.get("/repo/:year/:name", authenticate, function(request, response) {
	var repository = request.params.year+"/"+request.params.name;

	if (list.svn.indexOf(repository) < 0)
	{
		response.json(400, "Repository "+repository+" does not exist.");
		return;
	}

	response.json(200, "Getting a specific repo named "+repository);
});
app.post("/repo", authenticate, function(request, response) {
	response.status(200);
	response.json("Create a new repository.");
	updateListOfRepositories();
});

updateListOfRepositories();

http.createServer(app).listen(app.get("port"), function() {
	console.log("SVN Server listening on port " + app.get("port"));
});