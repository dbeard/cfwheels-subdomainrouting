SubDomainRouting
=======================

Add the ability to route via subdomains in your application. This is more a proof of concept for me - suggestions or complaints are welcome. I created this because I wanted to make different versions of the same app for different screens. For example, it's common for sites to serve mobile content using the `m.*` subdomain. So, essentially what I wanted was to set a property `screen` in the `params` struct that contains the subdomain that was entered. You are not limited to this however, you can specify `controller`,`action`,`key` and `format` in the subdomain as well. Putting all of these as subdomains is not recommended, nor would it work as you expect. I would recommend at least keeping the `controller` or `action` in the path pattern.

Props to the CFWheels team for making the routing system awesome!

Usage
--------------

Drop the plugin in your `plugins` folder and add the routes with a new property called `subdomainpattern`.

For example, if I wanted to include a `screen` variable in my params I would add the following routes:
	
	<cfset addRoute(pattern="[controller]/[action]/[key]", subdomainpattern="[screen]")>
	<cfset addRoute(pattern="[controller]/[action]", subdomainpattern="[screen]")>
	<cfset addRoute(pattern="[controller]", subdomainpattern="[screen]", action="index")>
	
I need to add all three to still match my regular routes. So, now when I visit `m.mysite.com`, the params struct will have a property `screen` equal to `'m'`. If I visit the site without a subdomain, it will match your previous routes without a subdomain pattern, and therefore the `screen` property will not exist.

You can also include several levels of subdomains if wanted. The pattern is made the same way as normal routing patterns, but subdomains are separated by a `'.'`. For example:

	<cfset addRoute(pattern="[action]/[key]", subdomainpattern="[screen].[controller]")>
	
This route would match a url like `http://m.user.mysite.com/view/12`. This would invoke the `User` controller with the action `view` and key `12`.

Pattern matching works by matching from right to left in subdomains. In other words, going back to this example:

	<cfset addRoute(pattern="[controller]/[action]/[key]", subdomainpattern="[screen]")>
	
This will match both `http://m.mysite.com/user/view/12` and also `http://blah.blah.m.mysite.com/user/view/12`. I can have as many sub-subdomains as I want, but it will only match the number specified in the pattern. In both instances, the `screen` property will be set to `m`.

Building From Source
----------------
	
	rake build
	
History
-------------------

Version 0.1 - Initial Release