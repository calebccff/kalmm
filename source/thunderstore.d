module thunderstore;

import std.stdio;
import std.net.curl;
import std.path;
import std.zip;

import std.datetime.date;
import std.string; //For strings too
import std.json;
import std.file;
import std.array;
import std.algorithm;
import std.net.curl;
import jsonizer;

import gtk.Clipboard;
import gtk.Main;
import gdk.Display;

import global;
import file_parallel.unzip_parallel;

class Thunderstore {

    Package[] packages;
    Package[] installed;

    private
    {
        const string _url = "https://thunderstore.io/";
        string installPath;
    }

    this() {
        installPath = buildPath(config.path, "BepInEx", "plugins");
    }

    void refreshPackages() {
        auto data = parseJSON(get(_url~"api/v1/package"));
        packages =  data.fromJSON!(Package[]);
    }

    void checkInstalled() {
        foreach(string dir; dirEntries(installPath, SpanMode.shallow)) {
            string[] packagesNames = packages.map!(pack => pack.full_name).array;
            writeln(packagesNames[0]);
            auto p = packages[packagesNames.countUntil(dir)]; //Finds the package with the matching full_name
            p.installed = true;
            installed ~= p; 
        }
    }

    void install(string uuid) { //The uid is '<owner>-<name>'
        //Install the package
        Package pack = packages[packages.map!(pack => pack.uuid4).array.countUntil(uuid)];
        writeln("Downloading: "~pack.name~"-"~pack.versions[0].version_number);
        download(pack.versions[0].download_url, installPath);
        writeln("Installing...");
        string packagePath = buildPath(installPath, pack.name~"-"~pack.versions[0].version_number);
        string zipPath = buildPath(installPath, pack.owner~"-"~pack.name~"-"~pack.versions[0].version_number);
        mkdir(packagePath);
        unzipParallel(zipPath, packagePath);
        remove(zipPath); //Delete the downloaded file
    }

    void copyInstalled(){ //Copy the list of installed mods to clipboard
        Clipboard clip = Clipboard.getDefault(Display.getDefault());
        string text = "";
        foreach(pack; packages) {
            if (pack.installed) {
                text ~= pack.uuid4~"\n";
            }
        }
        text ~= "TEST";
        clip.setText(text, -1);
    }
    void pasteInstalled(){ //Fetch (and install) mods list from clipboard TODO
        Clipboard clip = Clipboard.getDefault(Display.getDefault());
        writeln("Currently WIP, paste your mod list to a text file and use the import button");
        //string text = clip.requestText();
        //writeln(text);
    }
    void exportInstalled(){ //Export mods list to a file

    }
}

struct Version {
    mixin JsonizeMe;

    @jsonize {
        string name;
        string full_name;
        string description;
        string icon;
        string version_number;
        string[] dependancies;
        string download_url;
        int downloads;
        string website_url;
        bool is_active;
        string uuid4;
    }
    private DateTime _date_created;
    @property @jsonize {
        string date_created() { return _date_created.toString(); }
        void date_created(string str) { _date_created = DateTime.fromISOExtString(str[0..str.indexOf(".")]); }
    }
}

struct Package {
        mixin JsonizeMe;

        @jsonize {
            string name;
            string full_name;
            string owner;
            string package_url;
            string uuid4;
            bool is_pinned;
            bool is_deprecated;
            Version[] versions;
        }
        private DateTime _date_created;
        private DateTime _date_updated;
        @property @jsonize {
            string date_created() { return _date_created.toString(); }
            void date_created(string str) { _date_created = DateTime.fromISOExtString(str[0..str.indexOf(".")]); }
            string date_updated() { return _date_updated.toString(); }
            void date_updated(string str) { _date_updated = DateTime.fromISOExtString(str[0..str.indexOf(".")]); }
        }
        bool installed; //Is this package installed?
    }