import std.stdio;

import thunderstore;
import graphics;
import global;

import dlangui;
mixin DLANGUI_ENTRY_POINT;

extern (C) int UIAppMain(string[] args) {
	ts.refreshPackages();

	init();

	

	return 0;
}