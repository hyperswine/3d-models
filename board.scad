include <BOSL2/std.scad>

// should have two holes

// ── Parameters ──────────────────────────────────────────────
board_w = 220; // mm, X
board_d = 220; // mm, Y
board_t = 8; // panel face thickness

col_spacing = 20; // mm between columns (X)
row_spacing = 30; // mm between rows (Y)

hole_d = 5.0; // hole diameter (sized for M4 heat-set insert)
hole_depth = 6.0; // blind hole depth

margin = 10; // border before first/last hole

// ── Derived ─────────────────────────────────────────────────
cols = floor((board_w - 2 * margin) / col_spacing) + 1;
rows = floor((board_d - 2 * margin) / row_spacing) + 1;

col_positions = [for (i = [0:cols - 1]) -board_w / 2 + margin + i * col_spacing];
row_positions = [for (j = [0:rows - 1]) -board_d / 2 + margin + j * row_spacing];

// ── Main ─────────────────────────────────────────────────────
difference() {
  union() {
    // Face panel
    cuboid([board_w, board_d, board_t], anchor=BOTTOM);

  }

  // Blind holes for heat-set inserts (inset from front face)
  for (x = col_positions, y = row_positions)
    translate([x, y, 0])
      cyl(d=hole_d, h=hole_depth, anchor=BOTTOM, $fn=32);
}
