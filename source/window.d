module window;

import std.stdio;
import std.conv;

import gtk.MainWindow;
import gtk.Label;
import gtk.ListBox;
import gtk.ListBoxRow;
import gtk.ScrolledWindow;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.TreeModel;
import gtk.TreeModelFilter;
import gtk.CellRendererText;
import gtk.ListStore;
import gtk.TreeIter;
import gtk.Button;
import gtk.Image;
import gtk.CheckButton;
import gtk.Grid;
import gtk.Box;
import gtk.Main;
import gtk.Widget;

import thunderstore : Package;
import global;

PackageListStore availableList;
PackageTreeView available;

PackageListStore buildPackageList(Package[] delegate(Package[] packages) packFilter) {
    auto al = new PackageListStore();
    auto iter = al.createIter();
    foreach(pack; packFilter(ts.packages)) {
        //writeln("Appending pack "~pack.name);
        al.setValue(iter, 0, pack.name);
        al.setValue(iter, 1, pack.owner);
        al.setValue(iter, 2, pack.installed);
        al.setValue(iter, 3, pack.uuid4);
        al.append(iter);
    }
    return al;
}

PackageListStore buildPackageList() {
    return buildPackageList((packs) => packs);
}

void update() {
    availableList = buildPackageList();
    available.setModel(availableList);
}

struct Description {
    Label title;
    Label downloads;
    Label ver;
    Image icon;

    Widget[] iter() { 
        return [title, downloads, ver, icon];
    }
}
Description modDesc;

void init(string[] args) {
    Main.init(args);
    win = new MainWindow("Kalmm");
    win.setDefaultSize(1200, 600);
    win.setBorderWidth(4);
    Grid grid = new Grid();
    grid.setColumnHomogeneous(true);
    grid.setRowHomogeneous(true);
    win.add(grid);

    availableList = buildPackageList();

    available = new PackageTreeView(availableList);

    auto scrollable_availableList = new ScrolledWindow();
    grid.attach(scrollable_availableList, 0, 0, 2, 7);
    scrollable_availableList.add(available);
    scrollable_availableList.setBorderWidth(16);
    scrollable_availableList.setMinContentWidth(600);
    scrollable_availableList.setMinContentHeight(500);
    scrollable_availableList.setMaxContentWidth(600);
    scrollable_availableList.setMaxContentHeight(500);
    scrollable_availableList.setPropagateNaturalHeight(true);
    scrollable_availableList.setPropagateNaturalWidth(true);

    Button buttonInstall = new Button("Install", (Button btn) {
        TreeIter selected = available.getSelectedIter();
        ts.install(selected.getValueString(3)); //The uuid is not displayed
    });
    buttonInstall.setBorderWidth(2);
    grid.attach(buttonInstall, 0, 8, 1, 1);

    Button buttonRemove = new Button("Uninstall", (Button btn) {
        TreeIter selected = available.getSelectedIter();
        ts.uninstall(selected.getValueString(3)); //The uuid is not displayed
    });
    buttonInstall.setBorderWidth(2);
    grid.attach(buttonRemove, 0, 9, 1, 1);

    CheckButton checkShowInstalled = new CheckButton("Show installed", (CheckButton btn) {
        if(btn.getActive()){
            availableList = buildPackageList((packs) {
                Package[] filtered;
                foreach(pack; packs) {
                    if (pack.installed) {
                        filtered ~= pack;
                    }else {
                        writeln("Skipping "~pack.name);
                    }
                }
                return filtered;
            });
        }else{
            availableList = buildPackageList();
        }
        available.setModel(availableList);
    });
    grid.attach(checkShowInstalled, 1, 8, 1, 1);

    Button copyInstalled = new Button("Copy Mod List", (Button btn) {
        ts.copyInstalled();
    });
    grid.attach(copyInstalled, 3, 0, 1, 1);
    Button pasteInstalled = new Button("Paste Mod List", (Button btn) {
        ts.pasteInstalled();
    });
    grid.attach(pasteInstalled, 3, 1, 1, 1);
    Button exportInstalled = new Button("Export Mod List", (Button btn) {
        ts.exportInstalled();
    });
    grid.attach(exportInstalled, 4, 0, 1, 1);
    Button importMods = new Button("Import Mod List", (Button btn) {
        ts.importMods();
    });
    grid.attach(importMods, 4, 1, 1, 1);
    grid.attach(new Label("Put your mods list in a file called 'modslist.txt' next to this application"), 3, 2, 2, 1);


    ts.checkInstalled();
    win.showAll();
    Main.run();	
}

class PackageListStore : ListStore {
    this() {
        super([GType.STRING, GType.STRING, GType.BOOLEAN, GType.STRING]);
    }

    public void addPackage(in string name, in string owner, in bool installed, in string uuid) {
        TreeIter iter = createIter();
        setValue(iter, 0, name);
        setValue(iter, 1, owner);
        setValue(iter, 2, installed);
        setValue(iter, 3, uuid);
    }
}

class PackageTreeView : TreeView {
    private TreeViewColumn colName;
    private TreeViewColumn colOwner;
    private TreeViewColumn colInstalled;

    this(ListStore store) {
        colName = new TreeViewColumn(
            "Name", new CellRendererText(), "text", 0);
        appendColumn(colName);
        colOwner = new TreeViewColumn(
            "Owner", new CellRendererText(), "text", 1);
        appendColumn(colOwner);
        colInstalled = new TreeViewColumn(
            "Installed?", new CellRendererText(), "text", 2);
        appendColumn(colInstalled);

        setModel(store);
    }
}