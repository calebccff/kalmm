module graphics;

import global;
import dlangui;

void init() {
    window = createWindow("Kal's Mod Manager", null, WindowFlags.Resizable, 1200, 600);

    auto tlayout = new TableLayout();
    tlayout.colCount = 2;
    tlayout.margins = 8;
    tlayout.padding = 8;
}