include <BOSL2/std.scad>

// Variables optimized for a 30cm (300mm) miniature bow
bow_length = 300;   // Total length tip-to-tip in mm
handle_thick = 12;  // Thickness at the center handle
tip_thick = 4;      // Thickness at the tips
width = 10;         // Width of the limbs (into the Z plane)

$fn = 64;           // Smoothness of fragments

module bow_limb() {
    // 1. Define a more aggressive backbone curve
    p0 = [0, 0];
    // Moving p1 and p2 deeper into the negative Y territory makes it far curvier
    p1 = [bow_length/4, -25];  
    p2 = [bow_length/2, -65];  
    
    // Generate the points along this Bézier curve
    backbone = bezier_curve([p0, p1, p2], splinesteps=40); // Increased steps for smoothness
    
    // 2. Build a tapered profile by offsetting the backbone
    limb_points = [
        for (i = [0 : len(backbone)-1]) 
            let(
                t = i / (len(backbone)-1),
                current_thick = lerp(handle_thick/2, tip_thick/2, t),
                n = path_normals(backbone)[i]
            )
            backbone[i] + n * current_thick
    ];
    
    // Create the bottom half profile to close the loop
    limb_points_reverse = [
        for (i = [len(backbone)-1 : -1 : 0]) 
            let(
                t = i / (len(backbone)-1),
                current_thick = lerp(handle_thick/2, tip_thick/2, t),
                n = path_normals(backbone)[i]
            )
            backbone[i] - n * current_thick
    ];
    
    // Combine into a solid 2D polygon path
    full_limb_path = concat(limb_points, limb_points_reverse);
    
    // Extrude the 2D limb shape into 3D space
    linear_extrude(height=width, center=true) {
        polygon(full_limb_path);
    }
}

// Mirror the limb to create the full curvy longbow shape
union() {
    bow_limb();
    mirror([1, 0, 0]) bow_limb();
}