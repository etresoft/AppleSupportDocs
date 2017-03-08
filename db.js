var restify = require('restify');

// Parameters are: --port=port --db=/path/to/db
var args = require('minimist')(process.argv.slice(2));

function usage()
  {
  console.log("Usage: node db.js --port=nnn --db=/path/to/sqlitedb");
  }

if(args.port < 1)
  {
  console.log("Port invalid");
  usage();

  return;
  }

var fs = require("fs");

if(!fs.existsSync(args.db))
  {
  console.log("File " + args.db + " not found");
  usage();

  return;
  }

var server = 
  restify.createServer(
    {
    name: 'AppleSupportDocs',
    version: '1.0.0'
    });
    
server.use(restify.acceptParser(server.acceptable));
server.use(restify.queryParser());
server.use(restify.bodyParser());
server.use(
  function crossOrigin(request, response, next)
    {
    response.header("Access-Control-Allow-Origin", "*");
    response.header("Access-Control-Allow-Headers", "X-Requested-With");
    return next();
    });

var sqlite3 = require('sqlite3');
var db = new sqlite3.Database(args.db);

server.get(
  '/search/:text', 
  function (request, response, next) 
    {
    var data = 
      { 
      status: "success",
      records : []
      };
    
    db.each(
      "SELECT title, url from documents WHERE title like $1 order by title",    
      '%' + request.params.text + '%', 
      function(err, row)
        {
        if(err)
          {
          console.log("Error: " + err);
          data.status = err;
          }
        else
          {
          console.log(row.title + " => " + row.url);
          data.records.push(row);
          }
        },
      function()
        {
        response.send(data);

        return next();
        });
    });

server.get(
  '/category/:category', 
  function (request, response, next) 
    {
    var data = 
      { 
      status: "success",
      records : []
      };
    
    db.each(
      "SELECT title, url from documents WHERE category = $1 order by title",    
      request.params.category, 
      function(err, row)
        {
        if(err)
          {
          console.log("Error: " + err);
          data.status = err;
          }
        else
          {
          console.log(row.title + " => " + row.url);
          data.records.push(row);
          }
        },
      function()
        {
        response.send(data);

        return next();
        });
    });

server.get(
  '/categories', 
  function (request, response, next) 
    {
    var data = 
      { 
      status: "success",
      records : []
      };

    db.each(
      "SELECT distinct category from documents order by category",    
      request.params.text, 
      function(err, row)
        {
        if(err)
          {
          console.log("Error: " + err);
          data.status = err;
          }
        else
          {
          data.status = "test";
          console.log(row.category);
          data.records.push(row);
          }
        },
      function()
        {
        response.send(data);

        return next();
        });
    });

server.listen(
  args.port, 
  function () 
    {
    console.log('%s listening at %s', server.name, server.url);
    });
    

