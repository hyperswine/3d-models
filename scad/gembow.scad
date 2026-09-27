// ==================================================
// 3D Extruded Bow using Cubic Bézier Curves
// ==================================================

// --- Parameters ---
extrusion_height = 12; // Height/thickness of flat faces (Z-axis)
steps            = 25; // Number of interpolation steps per curve segment

// --- Cubic Bézier Math Helper ---
function bezier_cubic(p0, p1, p2, p3, t) =
    pow(1 - t, 3) * p0 +
    3 * pow(1 - t, 2) * t * p1 +
    3 * (1 - t) * pow(t, 2) * p2 +
    pow(t, 3) * p3;

function generate_curve(p0, p1, p2, p3, n) =
    [ for (i = [0 : n]) bezier_cubic(p0, p1, p2, p3, i / n) ];

// --- Control Points (Top Limb: [X = Depth/Curve, Y = Length]) ---

// 1. Outer Edge (Back of the bow)
p_out0 = [6, 0];       // Outer center handle
p_out1 = [35, 50];     // Main arch curve outwards
p_out2 = [25, 110];    // Upper limb tapering back
p_out3 = [8, 150];     // Tip base

// 2. Hook / Recurve Tip
p_hk0  = [8, 150];
p_hk1  = [0, 162];     // Curve around tip end
p_hk2  = [-14, 155];   // Hook curl back down
p_hk3  = [-7, 143];    // Inner tip junction

// 3. Inner Edge (Belly of the bow)
p_in0  = [-7, 143];
p_in1  = [18, 110];    // Inner limb profile
p_in2  = [27, 50];     // Inner grip swell
p_in3  = [-6, 0];      // Inner center handle

// --- Generate 2D Profile ---
pts_outer = generate_curve(p_out0, p_out1, p_out2, p_out3, steps);
pts_hook  = generate_curve(p_hk0, p_hk1, p_hk2, p_hk3, steps);
pts_inner = generate_curve(p_in0, p_in1, p_in2, p_in3, steps);

// Stitch point sets into a single loop for half the bow
half_bow_polygon = concat(pts_outer, pts_hook, pts_inner);

// --- Modules ---
module half_bow_2d() {
    polygon(points = half_bow_polygon);
}

module full_bow_3d() {
    linear_extrude(height = extrusion_height, center = true) {
        union() {
            half_bow_2d();
            mirror([0, 1, 0]) half_bow_2d(); // Mirror along Y-axis for bottom limb
        }
    }
}

// --- Render Model ---
full_bow_3d();