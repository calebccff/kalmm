import std.stdio;

import thunderstore;
import window;
import global;

void main(string[] args)
{
	writeln("Hello World");
	ts.refreshPackages();
	window.init(args);    
}