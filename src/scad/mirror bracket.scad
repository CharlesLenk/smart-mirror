include <openscad-utilities/common.scad>

$fn = 50;

spacer_horizontal_depth = 6;
spacer_vertical_depth = 4.5;

screw_tab_depth = 3.5;
screw_hole_dia = 5;

bracket_v2(spacer_vertical_depth);

module bracket_v2(spacer_depth) {
	bracket_width = 30;
	screw_tab_height = 18;
	mid_height = 4;
	spacer_height = 8;
	mid_depth = spacer_depth + 5;
	difference() {
		hull() {
			translate([bracket_width/2, 5, 0]) {
				cylinder(d = screw_hole_dia + 6, h = screw_tab_depth);
			}
			translate([0, screw_tab_height, 0]) {
				cube([bracket_width, mid_height, screw_tab_depth]);
			}
		}
		translate([bracket_width/2, 5, 0]) {
			cylinder(d = screw_hole_dia, h = 10, center = true);
		}
	}
	translate([0, screw_tab_height, 0]) {
		cube([bracket_width, mid_height, mid_depth]);
	}
	translate([0, screw_tab_height + mid_height, 0]) {
		cube([bracket_width, spacer_height, spacer_depth]);
	}
}
