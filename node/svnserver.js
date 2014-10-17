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

function authenticate(request, response, next)
{
	if (!request.header.token)
	{
		response.json(400, "Missing application token.");
		return;
	}

	for(var i = 0; i < authentication.length; i++)
	{
		if (authentication[i].key == request.header.token)
		{
			request.application = authentication[i];
			next(); return;
		}
	}

	response.json(400, "Invalid application token.");
}

app.get("/", function(request, response) {
	response.status(200);
	response.json("Welcome to the SVN Server!");
});
app.get("/repos", authenticate, function(request, response) {
	var repos = exec("find /home/svn/*/* -maxdepth 0 -type d | awk '{print substr($0, 11)}'", cmdOptions).output;
	console.log(repos);
	response.status(200);
	response.json("Get a list of all the SVN repositories!");
});
app.get("/repo/:name", authenticate, function(request, response) {
	response.status(200);
	response.json("Getting a specific repo named "+request.param.name);
});
app.post("/repo", authenticate, function(request, response) {
	response.status(200);
	response.json("Create a new repository.");
});

http.createServer(app).listen(app.get("port"), function() {
	console.log("SVN Server listening on port " + app.get("port"));
});