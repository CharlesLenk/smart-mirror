include <openscad-utilities/common.scad>

$fs = 0.5;
$fa = 1;

xy = 10;
z = 30;

tie_x = 2;
tie_y = 4;
tie_z = z + 2;

x = 5;

h = 5;
d = 3;

screw_distance = 30;
screw_diameter = 4.25;
screw_head_diameter = 7;
countersink_height = 3;
cable_diameter = 3.75;
cable_cut_adjustment = 4;
cutout_width = cable_diameter - 0.5;

y = cable_diameter + 12;
screw_holder_d = screw_head_diameter + 4;

bracket();

module bracket() {
    difference() {
        xy_cut() {
            hull () {
                translate([-screw_holder_d/2, -y/2, -h]) {
					rounded_cube([x + screw_holder_d, y, 2 * h], 3);
				}
                translate([0, -screw_distance/2, 0]) screw_cylinder();
                translate([0, screw_distance/2, 0]) screw_cylinder();
            }
        }
        translate([0, -screw_distance/2, 0]) screw_hole();
        translate([0, screw_distance/2, 0]) screw_hole();

        translate([screw_holder_d/2 - cable_diameter/2 + x, 0, 0]) rounded_cut();
        translate([screw_holder_d/2 - cable_diameter/2 + x, -cutout_width/2, -25]) {
			cube([50, cutout_width, 50]);
		}
    }

	module screw_cylinder() {
		rounded_cylinder(2 * h, screw_holder_d, 3, 3, center = true);
	}
}

module screw_hole() {
	cylinder(h = 50, d = screw_diameter, center = true);
	translate([0, 0, countersink_height]) cylinder(h = 50, d = screw_head_diameter);
}

module rounded_cut() {
    roundover_d = 2.5;
    difference() {
        cylinder(d = cable_diameter + roundover_d, h = h);
        difference () {
             translate([0, 0, roundover_d/2]) {
				 cylinder(d = cable_diameter + 2 * roundover_d, h = h - roundover_d);
			 }
            cylinder(d = cable_diameter, h = h);
        }
        translate([0, 0, roundover_d/2]) {
			torus(cable_diameter + roundover_d, roundover_d);
		}
        translate([0, 0, h - roundover_d/2]) {
			torus(cable_diameter + roundover_d, roundover_d);
		}
    }
}
