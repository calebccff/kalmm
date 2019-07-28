module global;

import std.file;
import std.json;
import std.stdio;
import gtk.MainWindow;

import thunderstore;
import window;

import jsonizer;

Package[] packages;
Thunderstore ts;
MainWindow win;

struct Config {
    mixin JsonizeMe;
    @jsonize{
        string path;
    }
}
Config config;

shared static this() {
    config = parseJSON(cast(string)read("config.json")).fromJSON!(Config);
    ts = new Thunderstore();
}