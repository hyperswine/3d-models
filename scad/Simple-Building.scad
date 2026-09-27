// Building dimensions
building_length = 100;
building_width = 100;
building_height = 200;
wall_thickness = 10;

// Window dimensions
window_length = 30;
window_width = 10;
window_height = 50;

// Create the main building structure
difference() {
    cube([building_length, building_width, building_height]); // Outer structure
    translate([wall_thickness, wall_thickness, wall_thickness]) {
        cube([building_length - 2*wall_thickness, building_width - 2*wall_thickness, building_height - wall_thickness]); // Inner cavity
    }
}

// Subtract windows from the building structure
difference() {
    // Building structure (from previous code block)
    difference() {
        cube([building_length, building_width, building_height]);
        translate([wall_thickness, wall_thickness, wall_thickness]) {
            cube([building_length - 2*wall_thickness, building_width - 2*wall_thickness, building_height - wall_thickness]);
        }
    }
    
    // Window openings
    translate([wall_thickness*2, 0, building_height/2]) {
        cube([window_length, window_width, window_height]); // Front window
    }
    translate([wall_thickness*2, building_width - window_width, building_height/2]) {
        cube([window_length, window_width, window_height]); // Back window
    }
}