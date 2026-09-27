// --- Parameters ---

// Length of each arm from the center vertex to the tip
arm_length = 150; // [mm]

// Width of the arms
arm_width = 25; // [mm]

// Thickness of the boomerang
thickness = 6; // [mm]

// Angle between the two arms
angle_between_arms = 110; // [degrees]

// Smoothness of curves (higher value = smoother, slower rendering)
smoothness = $fn > 0 ? $fn : 50; // Use $fn if defined, otherwise 50

// --- Geometry Generation ---

// Module defining a single arm shape (2D)
// It creates a shape resembling an arm by taking the hull of two circles.
module arm_shape_2d() {
    hull() {
        // Circle at the origin (vertex)
        circle(d = arm_width, $fn = smoothness);
        // Circle at the arm tip, translated along the x-axis
        translate([arm_length, 0, 0]) circle(d = arm_width, $fn = smoothness);
    }
}

// --- Main Boomerang Construction ---

// Use linear_extrude to give the 2D shape thickness
linear_extrude(height = thickness, center = true) {
    // Use union to combine the two arms
    union() {
        // First arm: Rotate half the angle negatively around Z-axis
        rotate([0, 0, -angle_between_arms / 2]) {
            arm_shape_2d();
        }
        // Second arm: Rotate half the angle positively around Z-axis
        rotate([0, 0, angle_between_arms / 2]) {
            arm_shape_2d();
        }
    }
}
