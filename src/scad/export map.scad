include <openscad-utilities/common.scad>
use <mirror cable clip.scad>
use <mirror screen case.scad>
use <mirror spacer.scad>

name = "";

if (name == "cable_clip")
    cable_clip();
else if (name == "foam_board_frame")
    foam_board_frame();
else if (name == "screen_case")
    screen_case();
else if (name == "snap_brace")
    snap_brace();
else if (name == "electronics_case")
    electronics_case();
else if (name == "assembly_brace")
    assembly_brace();
else if (name == "spacer")
    spacer(4.5);
