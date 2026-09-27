/*
color("red")
    translate([0, -30, 0])
        linear_extrude(height = 30)
            square([20, 10], center = true);

// using the scale parameter a frustum can be constructed
color("green")
    translate([-30, 0, 0])
        linear_extrude(height = 20, scale = 0.2)
            square([20, 10], center = true);

// with twist the extruded shape will rotate around the Z axis
color("cyan")
    translate([30, 0, 0])
        linear_extrude(height = 20, twist = 90)
            square([20, 10], center = true);

// combining both relatively complex shapes can be created
color("gray")
    translate([0, 30, 0])
        linear_extrude(height = 40, twist = -360, scale = 0, center = true, slices = 200)
            square([20, 10], center = true);
*/

// rectangular body
color("black")
    rotate([90, 0, 0])
    translate([0, 0, 0])
        linear_extrude(height = 30)
            square([20, 10], center = true);

// len = 30 made it 100
// height is weird
