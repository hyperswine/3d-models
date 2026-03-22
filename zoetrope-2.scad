// ── Zoetrope Moon Phase ──────────────────────────────────────────
// All dimensions in mm. Change n to recompute everything.

n          = 12;       // number of frames / slits
drum_r     = 60;       // drum inner radius
drum_h     = 50;       // drum wall height
wall_t     = 2;        // drum wall thickness
slit_w     = 3;        // slit width
slit_h     = 12;       // slit height
slit_inset = 8;        // slit distance from top rim

moon_r     = 8;        // moon radius on strip
strip_h    = drum_h;   // strip same height as drum
relief_d   = 0.6;      // relief extrusion depth (mm above strip surface)

base_r     = drum_r + wall_t + 8;
base_h     = 2.5;
handle_r   = 6;
handle_h   = 45;

$fn = 80;


module moon_phase_2d(i) {
    phase  = i / n;           // 0.0 → 1.0
    // offset sweeps: 2r (full cover) → 0 (no cover) → -2r (full cover other side)
    offset = moon_r * 2 * cos(phase * 180);

    if (i == 0) {
        // new moon - empty
    } else if (offset >= moon_r * 2 - 0.01) {
        // full moon
        circle(r = moon_r);
    } else {
        difference() {
            circle(r = moon_r);
            translate([offset, 0])
                circle(r = moon_r);
        }
    }
}

// ── One strip frame (flat, to be bent or used as unwrapped ref) ───
module strip_flat() {
    frame_w = (2 * PI * drum_r) / n;   // arc length per frame

    for (i = [0:n-1]) {
        tx = i * frame_w;
        // frame background
        translate([tx, 0, 0])
            cube([frame_w, strip_h, wall_t]);
        // moon relief centred in frame
        translate([tx + frame_w/2, strip_h * 0.45, wall_t])
            linear_extrude(relief_d)
                moon_phase_2d(i);
    }
}

// ── Drum ─────────────────────────────────────────────────────────
module drum() {
    difference() {
        // outer wall
        cylinder(h = drum_h, r = drum_r + wall_t);
        // hollow interior
        cylinder(h = drum_h, r = drum_r);
        // slits — n evenly spaced, near top
        for (i = [0:n-1]) {
            angle = i * (360 / n);
            rotate([0, 0, angle])
                translate([drum_r - 0.1, -slit_w/2, slit_inset])
                    cube([wall_t + 1, slit_w, slit_h]);
        }
    }
}

// ── Base plate ───────────────────────────────────────────────────
module base() {
    cylinder(h = base_h, r = base_r);
}

// ── Handle / spindle ─────────────────────────────────────────────
module handle() {
    // finger grip ridges
    cylinder(h = handle_h, r = handle_r);
    for (i = [0:7]) {
        translate([0, 0, 6 + i * 4.5])
            rotate_extrude()
                translate([handle_r, 0])
                    circle(r = 1.2);
    }
}

// ── Assembly ─────────────────────────────────────────────────────
// Comment/uncomment to print parts separately

// Full assembly preview
translate([0, 0, 0])         base();
translate([0, 0, -(handle_h)])  handle();
translate([0, 0, base_h])    drum();

// Flat strip for printing (uncomment to export separately)
// translate([-(PI * drum_r), -(strip_h * 1.5), 0])
//     strip_flat();


