// Bike Umbrella Holder
// By Claude, March 28, 2025

/* Parameters */
// Umbrella holder
umbrella_diameter = 25; // Diameter of umbrella shaft
umbrella_holder_thickness = 4; // Wall thickness of the umbrella holder
umbrella_holder_height = 60; // Height of umbrella cylinder

// Handlebar dimensions
handlebar_diameter = 25.4; // Standard handlebar diameter (1 inch)
bracket_length = 70; // Length of the bracket along the handlebar
bracket_thickness = 4; // Wall thickness of bracket

// Connector between umbrella holder and handlebar mount
connector_length = 30; // Length of connector piece
connector_width = 20; // Width of connector piece
connector_height = 15; // Height of connector

// Screw holes
screw_diameter = 6; // M6 screws
washer_diameter = 12; // Washer diameter
screw_positions = [ // Positions of the four screws
    [bracket_length/4, -handlebar_diameter/2 - bracket_thickness - 10],
    [bracket_length*3/4, -handlebar_diameter/2 - bracket_thickness - 10],
    [bracket_length/4, handlebar_diameter/2 + bracket_thickness + 10],
    [bracket_length*3/4, handlebar_diameter/2 + bracket_thickness + 10]
];

// Clearance for easier assembly
tolerance = 0.5;

/* Main Module */
module bike_umbrella_holder() {
    // Umbrella holder (vertical cylinder)
    translate([0, 0, connector_height + handlebar_diameter + bracket_thickness*2])
    umbrella_holder();

    // Connector between umbrella holder and handlebar mount
    translate([-connector_width/2, -connector_length/2, handlebar_diameter + bracket_thickness*2])
    connector();

    // Handlebar mount (upper and lower brackets)
    handlebar_mount();
}

/* Umbrella Holder Module */
module umbrella_holder() {
    difference() {
        // Outer cylinder
        cylinder(h=umbrella_holder_height, d=umbrella_diameter + umbrella_holder_thickness*2, $fn=60);

        // Inner cylinder (hole for umbrella)
        translate([0, 0, -1])
        cylinder(h=umbrella_holder_height+2, d=umbrella_diameter, $fn=60);
    }
}

/* Connector Module */
module connector() {
    difference() {
        // Connector body
        cube([connector_width, connector_length, connector_height]);

        // Hole for umbrella shaft (vertical alignment)
        translate([connector_width/2, connector_length/2, -1])
        cylinder(h=connector_height+2, d=umbrella_diameter/2, $fn=30);
    }
}

/* Handlebar Mount Module */
module handlebar_mount() {
    difference() {
        union() {
            // Upper bracket
            translate([-bracket_length/2, -handlebar_diameter/2 - bracket_thickness, handlebar_diameter + bracket_thickness])
            cube([bracket_length, handlebar_diameter + bracket_thickness*2, bracket_thickness]);

            // Lower bracket
            translate([-bracket_length/2, -handlebar_diameter/2 - bracket_thickness, 0])
            cube([bracket_length, handlebar_diameter + bracket_thickness*2, bracket_thickness]);

            // Side supports for upper bracket
            translate([-bracket_length/2, -handlebar_diameter/2 - bracket_thickness, bracket_thickness])
            cube([bracket_length, bracket_thickness, handlebar_diameter]);

            translate([-bracket_length/2, handlebar_diameter/2, bracket_thickness])
            cube([bracket_length, bracket_thickness, handlebar_diameter]);
        }

        // Cutout for handlebar
        translate([0, 0, bracket_thickness + handlebar_diameter/2])
        rotate([0, 90, 0])
        cylinder(h=bracket_length + 2, d=handlebar_diameter + tolerance, center=true, $fn=60);

        // Screw holes
        for (pos = screw_positions) {
            // Main screw holes
            translate([pos[0] - bracket_length/2, pos[1], -1])
            cylinder(h=bracket_thickness + handlebar_diameter + bracket_thickness + 2, d=screw_diameter, $fn=30);

            // Countersink for washer in lower bracket
            translate([pos[0] - bracket_length/2, pos[1], 0])
            cylinder(h=2, d=washer_diameter, $fn=30);

            // Countersink for washer in upper bracket
            translate([pos[0] - bracket_length/2, pos[1], handlebar_diameter + bracket_thickness - 2 + bracket_thickness])
            cylinder(h=2, d=washer_diameter, $fn=30);
        }
    }
}

/* Render the model */
//bike_umbrella_holder();

// Uncomment below to see the upper and lower parts separately for printing

module upperpart() {
// Upper part (umbrella holder and connector)
translate([0, 0, 0]) {
   translate([0, 0, connector_height + handlebar_diameter + bracket_thickness*2])
   umbrella_holder();

   translate([-connector_width/2, -connector_length/2, handlebar_diameter + bracket_thickness*2])
   connector();

   difference() {
       union() {
           // Upper bracket
           translate([-bracket_length/2, -handlebar_diameter/2 - bracket_thickness, handlebar_diameter + bracket_thickness])
           cube([bracket_length, handlebar_diameter + bracket_thickness*2, bracket_thickness]);

           // Side supports for upper bracket
           translate([-bracket_length/2, -handlebar_diameter/2 - bracket_thickness, bracket_thickness])
           cube([bracket_length, bracket_thickness, handlebar_diameter]);

           translate([-bracket_length/2, handlebar_diameter/2, bracket_thickness])
           cube([bracket_length, bracket_thickness, handlebar_diameter]);
       }

       // Cutout for handlebar
       translate([0, 0, bracket_thickness + handlebar_diameter/2])
       rotate([0, 90, 0])
       cylinder(h=bracket_length + 2, d=handlebar_diameter + tolerance, center=true, $fn=60);

       // Screw holes
       for (pos = screw_positions) {
           translate([pos[0] - bracket_length/2, pos[1], -1])
           cylinder(h=bracket_thickness + handlebar_diameter + bracket_thickness + 2, d=screw_diameter, $fn=30);

           translate([pos[0] - bracket_length/2, pos[1], handlebar_diameter + bracket_thickness - 2 + bracket_thickness])
           cylinder(h=2, d=washer_diameter, $fn=30);
       }
   }
}
}

upperpart();

module lowerpart() {
// Lower part (just the bottom bracket)
translate([0, 0, 0]) {
    difference() {
        // Lower bracket
        translate([-bracket_length/2, -handlebar_diameter/2 - bracket_thickness, 0])
        cube([bracket_length, handlebar_diameter + bracket_thickness*2, bracket_thickness]);

        // Screw holes with countersink
        for (pos = screw_positions) {
            translate([pos[0] - bracket_length/2, pos[1], -1])
            cylinder(h=bracket_thickness + 2, d=screw_diameter, $fn=30);

            translate([pos[0] - bracket_length/2, pos[1], 0])
            cylinder(h=2, d=washer_diameter, $fn=30);
        }
    }
}
}

lowerpart();
