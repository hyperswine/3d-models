// Pencil Case with Friction-Fit Lid
// Measurements in mm

/* Parameters */
// Main box dimensions
box_length = 180;    // Long enough for standard pencils
box_width = 60;      // Wide enough for multiple pencils and an eraser
box_height = 25;     // Height for pencils and small items
wall_thickness = 2;  // Wall thickness

// Lid dimensions
lid_height = 15;     // Height of the lid
lid_clearance = 0.3; // Clearance for friction fit (smaller = tighter fit)
lid_overlap = 10;    // How much the lid overlaps the box

// Friction bump parameters
bump_height = 0.8;   // Height of the friction bumps
bump_width = 5;      // Width of the friction bumps

/* Main Box */
module pencil_box() {
    difference() {
        // Outer box
        cube([box_length, box_width, box_height]);
        
        // Inner hollow
        translate([wall_thickness, wall_thickness, wall_thickness])
            cube([
                box_length - wall_thickness * 2, 
                box_width - wall_thickness * 2, 
                box_height + 1
            ]);
        
        // Cutout for lid
        translate([0, 0, box_height - lid_overlap])
            cube([
                box_length, 
                box_width, 
                lid_overlap + 1
            ]);
        
        // Friction bumps (indented into the box)
        translate([box_length/4, -1, box_height - lid_overlap/2])
            cube([bump_width, wall_thickness + 2, bump_height]);
        
        translate([box_length*3/4 - bump_width, -1, box_height - lid_overlap/2])
            cube([bump_width, wall_thickness + 2, bump_height]);
            
        translate([box_length/4, box_width - wall_thickness - 1, box_height - lid_overlap/2])
            cube([bump_width, wall_thickness + 2, bump_height]);
            
        translate([box_length*3/4 - bump_width, box_width - wall_thickness - 1, box_height - lid_overlap/2])
            cube([bump_width, wall_thickness + 2, bump_height]);
    }
}

/* Lid */
module pencil_lid() {
    difference() {
        // Outer lid
        cube([box_length, box_width, lid_height]);
        
        // Inner hollow
        translate([wall_thickness, wall_thickness, wall_thickness])
            cube([
                box_length - wall_thickness * 2, 
                box_width - wall_thickness * 2, 
                lid_height + 1
            ]);
    }
    
    // Inner lip that fits into the box
    translate([wall_thickness + lid_clearance, wall_thickness + lid_clearance, 0])
        difference() {
            cube([
                box_length - (wall_thickness + lid_clearance) * 2, 
                box_width - (wall_thickness + lid_clearance) * 2, 
                lid_overlap
            ]);
            
            // Hollow out the lip
            translate([wall_thickness, wall_thickness, -1])
                cube([
                    box_length - (wall_thickness + lid_clearance) * 2 - wall_thickness * 2, 
                    box_width - (wall_thickness + lid_clearance) * 2 - wall_thickness * 2, 
                    lid_overlap + 2
                ]);
        }
    
    // Friction bumps (extruded from the lid)
    translate([box_length/4, wall_thickness + lid_clearance, lid_overlap/2])
        cube([bump_width, bump_height, bump_height]);
    
    translate([box_length*3/4 - bump_width, wall_thickness + lid_clearance, lid_overlap/2])
        cube([bump_width, bump_height, bump_height]);
        
    translate([box_length/4, box_width - wall_thickness - lid_clearance - bump_height, lid_overlap/2])
        cube([bump_width, bump_height, bump_height]);
        
    translate([box_length*3/4 - bump_width, box_width - wall_thickness - lid_clearance - bump_height, lid_overlap/2])
        cube([bump_width, bump_height, bump_height]);
}

/* Render your choice by commenting/uncommenting */
// Render both parts separated for viewing
translate([0, 0, 0]) pencil_box();
translate([0, box_width + 20, 0]) pencil_lid();

// Uncomment to see the assembled case
// pencil_box();
// translate([0, 0, box_height - lid_overlap]) pencil_lid();