*%sphere(20);

$fn = 50;

*#translate([10, 0, 0]) sphere(20);

*translate([20,0,-20]) rotate(a=90, v=[1,1,0]) cylinder(r1=5,r2=2,h=20);

*union() {
 	cylinder (h = 4, r=1, center = true, $fn=100);
 	rotate ([90,0,0]) cylinder (h = 4, r=0.9, center = true, $fn=100);
 }
 
 difference() {
	cylinder (h = 4, r=1, center = true, $fn=100);
	rotate ([90,0,0]) cylinder (h = 4, r=0.9, center = true, $fn=100);
}
