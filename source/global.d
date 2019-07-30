module global;

import std.file;
import std.json;
import std.stdio;
import std.net.curl;
import etc.c.curl : CurlOption;
import gtk.MainWindow;

import thunderstore;
import window;

import jsonizer;

Package[] packages;
Thunderstore ts;
MainWindow win;
HTTP conn;

struct Config {
    mixin JsonizeMe;
    @jsonize{
        string path;
    }
}
Config config;

shared static this() {
    conn = HTTP();
    conn.handle.set(CurlOption.ssl_verifypeer, 0);
    config = parseJSON(cast(string)read("config.json")).fromJSON!(Config);
    ts = new Thunderstore();
}