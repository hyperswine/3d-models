// ========================================================
// Parametric Bow Arm / Limb Model
// Length: ~242mm (Bounding box < 250mm)
// Extrusion: Flat top/bottom faces
// ========================================================

$fn = 60; // Circle/curve resolution

// --- PARAMETERS ---
limb_thickness = 10;     // Extrusion thickness (Z-axis)
mount_width    = 25;     // Width at the central mounting block
m5_hole_dia    = 5.3;    // M5 screw clearance hole diameter (mm)

// --- BEZIER MATH HELPERS ---
// 4-point Cubic Bezier point calculation
function bezier_pt(p0, p1, p2, p3, t) =
    pow(1-t, 3)*p0 +
    3*pow(1-t, 2)*t*p1 +
    3*(1-t)*pow(t, 2)*p2 +
    pow(t, 3)*p3;

// Generate array of points along a Bezier curve
function bezier_curve(p0, p1, p2, p3, steps=25) =
    [ for (i = [0 : steps]) bezier_pt(p0, p1, p2, p3, i/steps) ];

// --- 2D BOW ARM PROFILE ---
module bow_arm_profile() {
    // Outer edge (Back of the bow arch)
    back_p0 = [0, mount_width];
    back_p1 = [70, mount_width + 12];
    back_p2 = [180, 22];
    back_p3 = [225, 26];

    // End Hook (Recurve tip)
    hook_p0 = [225, 26];
    hook_p1 = [242, 28];
    hook_p2 = [244, 10];
    hook_p3 = [232, 5];

    // Inner edge (Belly of the bow)
    belly_p0 = [232, 5];
    belly_p1 = [200, 8];
    belly_p2 = [100, 12];
    belly_p3 = [40, 0];

    // Generate curve point arrays
    c_back  = bezier_curve(back_p0, back_p1, back_p2, back_p3, 30);
    c_hook  = bezier_curve(hook_p0, hook_p1, hook_p2, hook_p3, 15);
    c_belly = bezier_curve(belly_p0, belly_p1, belly_p2, belly_p3, 30);

    // Combine into a single continuous polygon
    all_points = concat(
        [[0, 0]],
        [[0, mount_width]],
        c_back,
        c_hook,
        c_belly
    );

    polygon(points = all_points);
}

// --- 3D EXTRUDED ARM WITH M5 JOINTS ---
module bow_arm_3d() {
    difference() {
        // Flat extrusion along Z-axis
        linear_extrude(height = limb_thickness, center = true) {
            bow_arm_profile();
        }

        // M5 Screw Hole 1 (Center Joint)
        translate([12, mount_width / 2, 0])
            cylinder(d = m5_hole_dia, h = limb_thickness + 2, center = true);

        // M5 Screw Hole 2 (Center Joint)
        translate([28, mount_width / 2, 0])
            cylinder(d = m5_hole_dia, h = limb_thickness + 2, center = true);

        // String Nock Groove at the tip hook
        translate([234, 16, 0])
            rotate([0, 0, 40])
            cylinder(d = 4, h = limb_thickness + 2, center = true);
    }
}

// Render single bow arm
bow_arm_3d();

// --- PREVIEW BOTH ARMS JOINED (Uncomment to view) ---
/*
translate([0, 0, 0]) {
    bow_arm_3d();
    mirror([1, 0, 0]) bow_arm_3d();
}
*/