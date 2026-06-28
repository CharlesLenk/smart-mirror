include <openscad-utilities/common.scad>

screen_x = 111;
screen_y = 193;
screen_z = 9;
screen_corner_d = 16;

screen_screw_x = 65.5;
screen_screw_y = 126;
screen_screw_d = 3.1;

screen_edge_space = 0.05;
screen_cut_x = screen_x + 2 * screen_edge_space;
screen_cut_y = screen_y + 2 * screen_edge_space;
screen_cut_corner_d = screen_corner_d + 2 * screen_edge_space;

wall_width = 1.5;
wall_space = 0.25;

cutout_depth = 3.5;
cutout_overlap = 7;

screen_case_x = screen_cut_x + 2 * wall_width;
screen_case_y = screen_cut_y + 2 * wall_width;
screen_case_z = screen_z + wall_width;
screen_case_corner_d = screen_cut_corner_d + 2 * wall_width;

pi_cut_x = screen_case_x - 25;
pi_cut_y = screen_screw_y - 15;
pi_cut_corner_d = 35;

pi_case_interior_adjust = 5;
pi_case_interior_x = pi_cut_x + pi_case_interior_adjust;
pi_case_interior_y = pi_cut_y + pi_case_interior_adjust;
pi_case_interior_corner_d = pi_cut_corner_d + pi_case_interior_adjust;

pi_case_x = pi_case_interior_x + 2 * wall_width;
pi_case_y = pi_case_interior_y + 2 * wall_width;
pi_case_d = pi_case_interior_corner_d + 2 * wall_width;
pi_case_z = 34 + wall_width;

screen_screw_corner_pos = [23.5 + screen_edge_space, 32.25 + screen_edge_space];
pi_cut_pos = [
	-pi_cut_x/2 + screen_cut_x/2, -pi_cut_y/2 + screen_screw_corner_pos[1] + screen_screw_y/2
];
pi_case_pos = [
	-pi_case_interior_x/2 + screen_cut_x/2, -pi_case_interior_y/2 + screen_screw_corner_pos[1] + screen_screw_y/2, -pi_case_z
];

screw_holder_d = 8;
power_cut_y = 69;
power_cut_z = -15;

assembly(true);
translate([2 * pi_case_x, 0])
    assembly_brace();

module assembly(explode = false) {
    explode_dist = explode ? 30 : 0;
    foam_board_frame();
    translate([0, 0, -explode_dist])
        screen_case();
    translate([0, 0, -2 * explode_dist])
        case_back();
}

module screw_holder_flange() {
	d = screw_holder_d + 2 * cutout_overlap;
	intersection() {
		cylinder(d = d, h = wall_width);
		translate([-d/2, -d, 0]) {
			cube([d, d, wall_width]);
		}
	}
}

module screw_holder(h) {
	cylinder(d = screw_holder_d, h = h);
	translate([-screw_holder_d/2, 0, 0]) {
		cube([screw_holder_d, screw_holder_d/2, h]);
	}
}

module screen_screw_holes() {
	translate(screen_screw_corner_pos) {
		rotate(180) children();
		translate([screen_screw_x, 0]) {
			rotate(180) children();
		}
		translate([0, screen_screw_y]) {
			children();
		}
		translate([screen_screw_x, screen_screw_y]) {
			children();
		}
	}
}

module case_cut(d = wall_width + 0.2, h = 10, center = true) {
	length = 15;
	distance_from_cut = wall_width/2 + pi_case_interior_adjust/2;

	translate([pi_cut_x/2, 0, 0]) {
		hull() {
			translate([length/2, -distance_from_cut, 0]) {
				cylinder(d = d, h = h, center = center);
			}
			translate([-length/2, -distance_from_cut, 0]) {
				cylinder(d = d, h = h, center = center);
			}
		}
		hull() {
			translate([length/2, pi_cut_y + distance_from_cut, 0]) {
				cylinder(d = d, h = h, center = center);
			}
			translate([-length/2, pi_cut_y + distance_from_cut, 0]) {
				cylinder(d = d, h = h, center = center);
			}
		}
	}
	translate([0, pi_cut_y/2, 0]) {
		hull() {
			translate([-distance_from_cut, length/2, 0]) {
				cylinder(d = d, h = h, center = center);
			}
			translate([-distance_from_cut, -length/2, 0]) {
				cylinder(d = d, h = h, center = center);
			}
		}
		hull() {
			translate([pi_cut_x + distance_from_cut, length/2, 0]) {
				cylinder(d = d, h = h, center = center);
			}
			translate([pi_cut_x + distance_from_cut, -length/2, 0]) {
				cylinder(d = d, h = h, center = center);
			}
		}
	}
}

module screen_case() {
	difference() {
		union() {
			difference() {
				union () {
					translate([-wall_width, -wall_width, 0]) {
						rounded_cube(
						[
							screen_case_x,
							screen_case_y,
							screen_case_z
						], screen_case_corner_d, top_d = 0, bottom_d = 0);
					}
					translate([-2 * wall_width, -2 * wall_width, 0]) {
						rounded_frame([
							screen_case_x,
							screen_case_y,
							screen_case_z - cutout_depth - wall_width - 0.1],
							screen_case_corner_d,
							wall_width
						);
					}
				}
				translate([0, 0, wall_width]) {
					rounded_cube(
					[
						screen_cut_x,
						screen_cut_y,
						screen_case_z
					], screen_cut_corner_d, top_d = 0, bottom_d = 0);
				}
				screen_screw_holes() cylinder(d = screen_screw_d, h = 10, center = true);
				translate([0, 0, -1]) {
					translate(pi_cut_pos) {
						rounded_cube(
						[
							pi_cut_x,
							pi_cut_y,
							screen_case_z + 2
						], pi_cut_corner_d, top_d = 0, bottom_d = 0);
						case_cut();
					}
				}
			}
			place_corner_screw_holders() {
				screw_holder(screen_case_z - cutout_depth - wall_width);
			}
		}
		place_corner_screw_holders() {
			translate([0, 0, 1]) rotate([180, 0, 0]) countersink(3.1, 6.3);
		}
	}
}

module assembly_brace() {
    difference() {
        translate([-2 * wall_width - wall_space/2, -2 * wall_width - wall_space/2, 0]) {
            translate([-wall_width, -wall_width, 0]) {
                squared_frame2([
                    screen_case_x + wall_space,
                    screen_case_y + wall_space,
                    cutout_depth],
                    screen_case_corner_d + wall_space,
                    2 * wall_width
                );
            }
        }
    }
}

module squared_frame2(vector, corner_d, wall_width) {
	difference() {
		union() {
			cube(
			[
				vector[0] + 2 * wall_width,
				vector[1] + 2 * wall_width,
				wall_width
			]);
			translate([wall_width, wall_width, 0]) {
				rounded_cube(
				[
					vector[0],
					vector[1],
					wall_width + cutout_depth
				], corner_d, top_d = 0, bottom_d = 0);
			}
		}
		translate([2 * wall_width, 2 * wall_width, -1]) {
			rounded_cube(
			[
				vector[0] - 2 * wall_width,
				vector[1] - 2 * wall_width,
				vector[2] + 7
			], corner_d, top_d = 0, bottom_d = 0);
		}
	}
	intersection() {
		translate([-15, -15]) cube_hash();
		translate([2 * wall_width, 2 * wall_width, -1]) {
			rounded_cube(
			[
				vector[0] - 2 * wall_width,
				vector[1] - 2 * wall_width,
				vector[2] + 7
			], corner_d, top_d = 0, bottom_d = 0);
		}
	}
}

module case_back() {
	holder_h = 4;

	translate([pi_cut_pos[0], pi_cut_pos[1], 0]) {
		case_cut(d = wall_width, h = wall_width, center = false);
	}

	difference() {
		union() {
			translate(pi_case_pos) {
				translate([-wall_width, -wall_width, 0]) {
					rounded_cube(
					[
						pi_case_x,
						pi_case_y,
						pi_case_z
					], pi_cut_corner_d, top_d = 0, bottom_d = 0);
				}
			}
			translate([0, 0, -holder_h]) {
				screen_screw_holes() {
					hull() {
						cylinder(d = screw_holder_d, h = holder_h);
						translate([0, -screw_holder_d, 0]) {
							cylinder(d = screw_holder_d, h = holder_h);
						}
					}
				}
			}
		}
		hull() {
			translate([0, power_cut_y + 2, power_cut_z]) {
				rotate([0, 90, 0]) cylinder(d = 12, h = 20, center = true);
			}
			translate([0, power_cut_y - 2, power_cut_z]) {
				rotate([0, 90, 0]) cylinder(d = 12, h = 20, center = true);
			}
		}
		translate(pi_case_pos) {
			translate([0, 0, wall_width]) {
				rounded_cube(
				[
					pi_case_interior_x,
					pi_case_interior_y,
					pi_case_z
				], pi_cut_corner_d, top_d = 0, bottom_d = 0);
			}
		}
		translate([0, 0, -holder_h]) {
			screen_screw_holes() {
				rotate([180, 0, 0]) countersink(3.1, 6.3);
			}
		}
		intersection() {
			translate([0, 0, -pi_case_z]) {
				hexagon_grid(pi_case_x, pi_case_y, 5, 2, 5);
			}
			translate(pi_case_pos) {
				translate([0, 0, -10]) {
					rounded_cube(
					[
						pi_case_interior_x,
						pi_case_interior_y,
						pi_case_z
					], pi_cut_corner_d, top_d = 0, bottom_d = 0);
				}
			}
		}
	}
}

module cube_hash() {
	dist = 25;
	for(i = [0 : 15]) {
		translate([0, i * dist]) {
			cube([240, 1.5, 5]);
		}
		translate([i * dist, 0]) {
			cube([1.5, 240, 5]);
		}
	}
}

module foam_board_frame() {
	difference() {
		union() {
			translate([-2 * wall_width - wall_space, -2 * wall_width - wall_space, 0]) {
				translate([-wall_width, -wall_width, screen_case_z - cutout_depth]) {
					squared_frame([
						screen_case_x + 2 * wall_space,
						screen_case_y + 2 * wall_space,
						cutout_depth],
						screen_case_corner_d + wall_space,
						2 * wall_width
					);
				}
				translate([-cutout_overlap - wall_width, -cutout_overlap - wall_width, screen_case_z - cutout_depth - wall_width]) {
					squared_frame([
						screen_case_x + 2 * wall_space,
						screen_case_y + 2 * wall_space,
						wall_width],
						screen_case_corner_d + wall_space,
						2 * wall_width + cutout_overlap
					);
				}
			}
		}
		translate([0, 0, screen_case_z - cutout_depth - wall_width]) {
			place_corner_screw_holders() {
				rotate([180, 0, 0]) threaded_insert_hole();
			}
		}
	}
}

module place_corner_screw_holders() {
	corner_adjust = 1.5;
	translate([-corner_adjust, -corner_adjust, 0]) {
		rotate(-45) children();
	}
	translate([screen_cut_x + corner_adjust, -corner_adjust, 0]) {
		rotate(45) children();
	}
	translate([-corner_adjust, screen_cut_y + corner_adjust, 0]) {
		rotate(-135) children();
	}
	translate([screen_cut_x + corner_adjust, screen_cut_y + corner_adjust, 0]) {
		rotate(135) children();
	}
}

module squared_frame(vector, corner_d, wall_width) {
	difference() {
		cube(
		[
			vector[0] + 2 * wall_width,
			vector[1] + 2 * wall_width,
			vector[2]
		]);
		translate([wall_width, wall_width, -1]) {
			rounded_cube(
			[
				vector[0],
				vector[1],
				vector[2] + 2
			], corner_d, top_d = 0, bottom_d = 0);
		}
	}
}

module rounded_frame(vector, corner_d, wall_width) {
	difference() {
		rounded_cube(
		[
			vector[0] + 2 * wall_width,
			vector[1] + 2 * wall_width,
			vector[2]
		], corner_d + 2 * wall_width, top_d = 0, bottom_d = 0);
		translate([wall_width, wall_width, -1]) {
			rounded_cube(
			[
				vector[0],
				vector[1],
				vector[2] + 2
			], corner_d, top_d = 0, bottom_d = 0);
		}
	}
}

module hexagon_grid(x, y, side_size, distance, h) {
    yi = y / (distance + side_size) * 1.3;
    xi = x / (distance + side_size) * 1.3;

    for (j = [0 : xi]) {
        translate([
            j * (side_size + distance) * sqrt(3) / 2,
            (j % 2) * -(side_size + distance)/2,
            0
        ]) {
            for (i = [0 : yi]) {
                translate([0, i * (distance + side_size), -0.01]) {
                    cylinder(d = 1.154 * side_size, h = h + 0.02, $fn = 6);
                }
            }
        }
    }
}
