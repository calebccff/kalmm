module global;

import std.file;
import std.json;
import std.stdio;

import thunderstore;

import jsonizer;

Package[] packages;
Thunderstore ts;

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