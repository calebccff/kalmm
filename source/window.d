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
import gtk.CheckButton;
import gtk.Grid;
import gtk.Box;
import gtk.Main;

import thunderstore : Package;
import global;

void init(string[] args) {
    Main.init(args);
    MainWindow win = new MainWindow("Kalmm");
    win.setDefaultSize(1200, 600);
    win.setBorderWidth(16);
    Grid grid = new Grid();
    grid.setColumnHomogeneous(false);
    grid.setRowHomogeneous(false);
    win.add(grid);

    PackageListStore availableList = new PackageListStore();
    foreach(pack; ts.packages) {
        availableList.addPackage(pack.name, pack.owner, pack.installed, pack.uuid4);
    }

    PackageTreeView available = new PackageTreeView(availableList);

    auto scrollable_availableList = new ScrolledWindow();
    grid.attach(scrollable_availableList, 0, 0, 2, 7);
    scrollable_availableList.add(available);
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

    CheckButton checkShowInstalled = new CheckButton("Show installed", (CheckButton btn) {
        if(btn.getActive()){
            auto filter = new TreeModelFilter(cast(ListStore)availableList, null);
            filter.setVisibleFunc(cast(GtkTreeModelFilterVisibleFunc) &filterInstalled, null, null);
            available.setModel(filter);
        }else{
            available.setModel(availableList);
        }
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


    
    win.showAll();
    Main.run();	
}

static extern(C) int filterInstalled(GtkTreeModel* gtkModel, GtkTreeIter* gtkIter, void* data) //uhhhhhhhhhhhhhhhhhhhhhhh
{
    auto model1 = new TreeModel(gtkModel, false);
    auto it1 = new TreeIter(gtkIter, false);

    bool installed = model1.getValueString(it1, 2) == "TRUE";
    return installed;
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