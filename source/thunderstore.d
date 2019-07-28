module thunderstore;

import std.stdio;
import std.net.curl;
import std.path;
import std.zip;

import core.exception;

import std.datetime.date;
import std.string; //For strings too
import std.json;
import std.file;
import std.array;
import std.algorithm;
import std.net.curl;
import jsonizer;

import gtk.Clipboard;
import gdk.Display;
import gtk.Main;

import global;
import window;

class Thunderstore {

    Package[] packages;

    private
    {
        const string _url = "https://thunderstore.io/";
        string installPath;
    }

    this() {
        installPath = buildPath(config.path, "BepInEx", "plugins/");
    }

    void refreshPackages() {
        auto data = parseJSON(get(_url~"api/v1/package"));
        packages = data.fromJSON!(Package[]);
    }

    void checkInstalled() {
        string[] packagesNames = packages.map!(pack => pack.name~"-"~pack.uuid4).array;
        foreach(string dir; dirEntries(installPath, SpanMode.shallow)) {
            if(dir.isFile) continue;
            writeln(dir);
            dir = dir.split(dirSeparator)[$-1];
            writeln(dir);
            try{
                packages[packagesNames.countUntil(dir)].installed = true; //Finds the package with the matching full_name
            }catch(RangeError e){
                writeln(e);
            }
        }
        window.update();
    }

    void install(string uuid) { //The uid is '<owner>-<name>'
        //Install the package
        Package pack = packages[packages.map!(pack => pack.uuid4).array.countUntil(uuid)];
        string packagePath = buildPath(installPath, pack.name~"-"~pack.uuid4);
        string zipPath = buildPath(installPath, pack.name~".zip");
        if(packagePath.exists) {
            writeln("Mod already installed, if this is an error delete the mod folder:\n"~packagePath~"\nand reinstall");
            return;
        }
        writeln("Downloading: "~pack.name~"-"~pack.uuid4);
        
        download(pack.versions[0].download_url, zipPath);
        writeln("Installing...");
        
        
        mkdir(packagePath);
        version(linux) {
            import std.process : executeShell;
            string execString = "cd \""~packagePath~"\" && unzip \""~zipPath~"\"";
            writeln("Running: "~execString);
            executeShell(execString);
        }
        version(windows) {
            import std.process : executeShell;
            writeln("Installing doesn't work on windows yet...");
        }
        remove(zipPath); //Delete the downloaded file
        writeln(pack.versions[0].dependencies);
        foreach(dep; pack.versions[0].dependencies) {
            if (dep.indexOf("BepInExPack") > 0 || dep.indexOf("R2API") > 0) continue; //Don't need this one...
            writeln("Installing dependancy: "~dep);
            dep = dep.split("-")[0..$-1].join("-"); //Remove version number, for now we just get the latest version
            try{
                Package depen = packages[packages.map!(pack => pack.owner~"-"~pack.name).array.countUntil(dep)];
                install(depen.uuid4);
            }catch(RangeError e){
                writeln("Failed to find dependancy for "~pack.name);
            }
        }
        packages[packages.map!(pack => pack.uuid4).array.countUntil(uuid)].installed = true;
        window.update();
    }
    void uninstall(string uuid) {
        Package pack = packages[packages.map!(pack => pack.uuid4).array.countUntil(uuid)];
        if (!pack.installed) return;
        string packagePath = buildPath(installPath, pack.name~"-"~pack.uuid4);
        packages[packages.map!(pack => pack.uuid4).array.countUntil(uuid)].installed = false;
        packagePath.rmdirRecurse();
        window.update();
    }

    void copyInstalled(){ //Copy the list of installed mods to clipboard
        Clipboard clip = Clipboard.getDefault(Display.getDefault());
        string text = getInstalledList().join("\n");
        clip.setText(text, -1);
        writeln("Copied modslist to your clipboard");
    }

    string[] getInstalledList() {
        string[] ilist;
        foreach(pack; packages) {
            if (pack.installed) {
                ilist ~= pack.uuid4;
            }
        }
        return ilist;
    }

    void pasteInstalled(){ //Fetch (and install) mods list from clipboard TODO
        Clipboard clip = Clipboard.getDefault(Display.getDefault());
        writeln("Currently WIP, paste your mod list to a text file and use the import button");
        //string text = clip.requestText();
        //writeln(text);
    }
    void exportInstalled(){ //Export mods list to a file
        File("modslist.txt", "w").write(getInstalledList().join("\n"));
        writeln("Exported mods as 'modslist.txt'");
    }
    void importMods() {
        writeln("Importing mods from 'modslist.txt'");
        string[] mods = (cast(string)read("modslist.txt")).split("\n");
        foreach(uuid; mods) {
            install(uuid);
        }
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
        string[] dependencies;
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
        Description desc;
    }