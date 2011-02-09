<cfcomponent output="false">

    <cffunction name="init">
        <cfset this.version = "1.1,1.1.1,1.1.2">
        <cfreturn this>
    </cffunction>

	<cffunction name="addRoute" returntype="void" access="public" output="false" hint="Adds a new route to your application."
		categories="configuration" chapters="using-routes" functions="">
		<cfargument name="name" type="string" required="false" default="" hint="Name for the route. This is referenced as the `name` argument in functions based on @URLFor like @linkTo, @startFormTag, etc.">
		<cfargument name="pattern" type="string" required="true" hint="The URL pattern that the route will match.">
		<cfargument name="controller" type="string" required="false" default="" hint="Controller to call when route matches (unless the controller name exists in the pattern).">
		<cfargument name="action" type="string" required="false" default="" hint="Action to call when route matches (unless the action name exists in the pattern).">
		<cfargument name="subdomainpattern" type="string" required="false" default="" hint="The Subdomain pattern to match">
		<cfscript>
			var loc = {};

			// throw errors when controller or action is not passed in as arguments and not included in the pattern
			if (!Len(arguments.controller) && arguments.pattern Does Not Contain "[controller]")
				$throw(type="Wheels.IncorrectArguments", message="The `controller` argument is not passed in or included in the pattern.", extendedInfo="Either pass in the `controller` argument to specifically tell Wheels which controller to call or include it in the pattern to tell Wheels to determine it dynamically on each request based on the incoming URL.");
			if (!Len(arguments.action) && arguments.pattern Does Not Contain "[action]")
				$throw(type="Wheels.IncorrectArguments", message="The `action` argument is not passed in or included in the pattern.", extendedInfo="Either pass in the `action` argument to specifically tell Wheels which action to call or include it in the pattern to tell Wheels to determine it dynamically on each request based on the incoming URL.");

			loc.thisRoute = Duplicate(arguments);
			loc.thisRoute.variables = "";
			if (Find(".", loc.thisRoute.pattern))
			{
				loc.thisRoute.format = ListLast(loc.thisRoute.pattern, ".");
				loc.thisRoute.formatVariable = ReplaceList(loc.thisRoute.format, "[,]", "");
				loc.thisRoute.pattern = ListFirst(loc.thisRoute.pattern, ".");
			}
			loc.iEnd = ListLen(loc.thisRoute.pattern, "/");
			for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
			{
				loc.item = ListGetAt(loc.thisRoute.pattern, loc.i, "/");

				if (REFind("^\[", loc.item))
					loc.thisRoute.variables = ListAppend(loc.thisRoute.variables, ReplaceList(loc.item, "[,]", ""));
			}
			
			loc.iEnd = ListLen(loc.thisRoute.subdomainpattern, ".");
			for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
			{
				loc.item = ListGetAt(loc.thisRoute.subdomainpattern, loc.i, ".");

				if (REFind("^\[", loc.item))
					loc.thisRoute.variables = ListAppend(loc.thisRoute.variables, ReplaceList(loc.item, "[,]", ""));
			}
			
			ArrayAppend(application.wheels.routes, loc.thisRoute);
		</cfscript>
	</cffunction>
	
	
	<cffunction name="$findMatchingRoute" returntype="struct" access="public" output="false">
		<cfargument name="path" type="string" required="true">
		<cfargument name="subdomain" type="string" required="true">
		<cfargument name="format" type="string" required="true" />
		<cfscript>			
			var loc = {};

			loc.iEnd = ArrayLen(application.wheels.routes);
			for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
			{
				loc.format = false;
				if (StructKeyExists(application.wheels.routes[loc.i], "format"))
					loc.format = application.wheels.routes[loc.i].format;
				loc.currentSubDomain = application.wheels.routes[loc.i].subdomainpattern;
				loc.domainMatch = true;
				if (ListLen(arguments.subdomain, ".") gte ListLen(loc.currentSubDomain, ".") && loc.currentSubDomain != "")
				{
					loc.jEnd = ListLen(loc.currentSubDomain, ".");
					for (loc.j=1; loc.j <= loc.jEnd; loc.j++)
					{
						loc.item = ListGetAt(loc.currentRoute, loc.j, ".");
						loc.thisRoute = ReplaceList(loc.item, "[,]", "");
						loc.thisURL = ListGetAt(arguments.subdomain, loc.j, ".");
						if (Left(loc.item, 1) != "[" && loc.thisRoute != loc.thisURL){
							loc.domainMatch = false;
							break;
						}
					}
				}
				
				if(loc.domainMatch){
					loc.currentRoute = application.wheels.routes[loc.i].pattern;
					if (loc.currentRoute == "*") {
						loc.returnValue = application.wheels.routes[loc.i];
						break;
					} 
					else if (arguments.path == "" && loc.currentRoute == "")
					{
						loc.returnValue = application.wheels.routes[loc.i];
						break;
					}
					else if (ListLen(arguments.path, "/") gte ListLen(loc.currentRoute, "/") && loc.currentRoute != "")
					{
						loc.match = true;
						loc.jEnd = ListLen(loc.currentRoute, "/");
						for (loc.j=1; loc.j <= loc.jEnd; loc.j++)
						{
							loc.item = ListGetAt(loc.currentRoute, loc.j, "/");
							loc.thisRoute = ReplaceList(loc.item, "[,]", "");
							loc.thisURL = ListGetAt(arguments.path, loc.j, "/");
							if (Left(loc.item, 1) != "[" && loc.thisRoute != loc.thisURL)
								loc.match = false;
						}
						if (loc.match)
						{
							loc.returnValue = application.wheels.routes[loc.i];
							if (Len(arguments.format) && !IsBoolean(loc.format))
								loc.returnValue[ReplaceList(loc.format, "[,]", "")] = arguments.format;
							break;
						}
					}
				}
			}
			if (!StructKeyExists(loc, "returnValue"))
				$throw(type="Wheels.RouteNotFound", message="Wheels couldn't find a route that matched this request.", extendedInfo="Make sure there is a route setup in your `config/routes.cfm` file that matches the `#arguments.path#` request.");
			</cfscript>
			<cfreturn loc.returnValue>
	</cffunction>
	
	<cffunction name="$request" returntype="string" access="public" output="false">
		<cfargument name="pathInfo" type="string" required="false" default="#request.cgi.path_info#">
		<cfargument name="scriptName" type="string" required="false" default="#request.cgi.script_name#">
		<cfargument name="formScope" type="struct" required="false" default="#form#">
		<cfargument name="urlScope" type="struct" required="false" default="#url#">
		<cfargument name="domain" type="string" required="false" default="#request.cgi.server_name#">
		<cfscript>
			var loc = {};
			if (application.wheels.showDebugInformation)
				$debugPoint("setup");

			// determine the path from the url, find a matching route for it and create the params struct
			loc.path = $getPathFromRequest(pathInfo=arguments.pathInfo, scriptName=arguments.scriptName);
			loc.format = $getFormatFromRequest(pathInfo=arguments.pathInfo);
			loc.subdomain = $getSubDomainFromHost(host=arguments.domain);
			loc.route = $findMatchingRoute(path=loc.path, subdomain=loc.subdomain, format=loc.format);
			loc.params = $createParams(path=loc.path, subdomain=loc.subdomain, format=loc.format, route=loc.route, formScope=arguments.formScope, urlScope=arguments.urlScope);

			// set params in the request scope as well so we can display it in the debug info outside of the dispatch / controller context
			request.wheels.params = loc.params;

			if (application.wheels.showDebugInformation)
				$debugPoint("setup");

			// create the requested controller
			loc.controller = controller(name=loc.params.controller, params=loc.params);

			// if the controller fails to process, instantiate a new controller and try again
			if (!loc.controller.$processAction())
			{
				loc.controller = controller(name=loc.params.controller, params=loc.params);
				loc.controller.$processAction();
			}

			// if there is a delayed redirect pending we execute it here thus halting the rest of the request
			if (loc.controller.$performedRedirect())
				$location(argumentCollection=loc.controller.$getRedirect());

			// clear out the flash (note that this is not done for redirects since the processing does not get here)
			loc.controller.$flashClear();
		</cfscript>
		<cfreturn loc.controller.response()>
	</cffunction>
	
	<cffunction name="$createParams" returntype="struct" access="public" output="false">
		<cfargument name="path" type="string" required="true">
		<cfargument name="subdomain" type="string" required="true">
		<cfargument name="format" type="string" required="true">
		<cfargument name="route" type="struct" required="true">
		<cfargument name="formScope" type="struct" required="true">
		<cfargument name="urlScope" type="struct" required="true">
		<cfscript>
			loc = {};
			loc.returnValue = core.$createParams(argumentCollection=arguments);
			
			// go through the matching route pattern and add URL variables from the route to the struct
			loc.iEnd = ListLen(arguments.route.subdomainpattern, ".");
			trace(arguments.route.subdomainpattern);
			trace(arguments.subdomain);
			for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
			{
				loc.item = ListGetAt(arguments.route.subdomainpattern, loc.i, ".");
				if (Left(loc.item, 1) == "[")
					loc.returnValue[ReplaceList(loc.item, "[,]", "")] = ListGetAt(arguments.subdomain, loc.i, ".");
			}
		</cfscript>
		<cfreturn loc.returnValue>
	</cffunction>
	
	<cffunction name="$getSubDomainFromHost" returntype="string" output="false">
		<cfargument name="host" type="string" required="true">
		<cfscript>
			//Return everything except for host.tld
			
			len = ListLen(arguments.host, ".");
			
			if(len < 3)
				return "";
				
			return ListDeleteAt(ListDeleteAt(arguments.host,len,"."),len-1,".");
		</cfscript>
	</cffunction>
</cfcomponent>