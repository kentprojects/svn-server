/**
 * @category: SVN-Server
 * @author: James Dryden <jsd24@kent.ac.uk>
 * @license: Copyright KentProjects
 * @link: http://www.kentprojects.com
 */
var config = require("./config.json"),
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
	app.set("port", process.env.PORT || config.port);
	app.use(express.logger("dev"));
	app.use(express.favicon());
	app.use(express.json());
	app.use(express.urlencoded({limit: "10mb"}));
	app.use(express.methodOverride());
	app.use(event.build);
	app.use(action.device.findByUserAgent);
	app.use(app.router);
});

app.configure("development", function() {
	app.use(express.errorHandler());
});

app.get("/", action.index);

http.createServer(app).listen(app.get("port"), function() {
	console.log("SVN Server listening on port " + app.get("port"));
});