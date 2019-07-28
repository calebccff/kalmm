import std.stdio;

import thunderstore;
import window;
import global;

void main(string[] args)
{
	ts.refreshPackages();
	window.init(args);    
}