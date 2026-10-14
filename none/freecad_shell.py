# type: ignore
import FreeCAD as App
import Part
import ObjectsFem
import femtools.ccxtools as ccxtools
from femmesh.gmshtools import GmshTools

doc = App.newDocument("TubeShellFEA")

# 1. Geometry — Construct 2D mid-surface shell
# Wall thickness t = R_outer - R_inner = 5.0 mm
# Mid-surface radius R_mid = (R_outer + R_inner) / 2 = 7.5 mm
outer_r = 10.0  # mm
inner_r = 5.0   # mm
height = 1000.0 # mm

wall_thickness = outer_r - inner_r  # 5.0 mm
mid_r = (outer_r + inner_r) / 2.0    # 7.5 mm

# Create a circle at mid-radius and extrude it into a surface shell
circle = Part.makeCircle(mid_r)
wire = Part.Wire([circle])
tube_surface = wire.extrude(App.Vector(0, 0, height))

tube_obj = doc.addObject("Part::Feature", "MyTubeShell")
tube_obj.Shape = tube_surface
doc.recompute()

# 2. Analysis container
analysis = ObjectsFem.makeAnalysis(doc, "Analysis")

# 3. Material assignment
material = ObjectsFem.makeMaterialSolid(doc, "Aluminium")
mat = material.Material
mat["Name"] = "Aluminium-6061"
mat["YoungsModulus"] = "69000 MPa"
mat["PoissonRatio"] = "0.33"
mat["Density"] = "2700 kg/m^3"
material.Material = mat
analysis.addObject(material)

# 4. Shell Element Geometry (Thickness property)
shell_thickness = ObjectsFem.makeElementGeometry2D(doc, thickness=wall_thickness, name="ShellThickness")
analysis.addObject(shell_thickness)

# 5. 2D Mesh Generation (Gmsh)
mesh_obj = ObjectsFem.makeMeshGmsh(doc, "FEMMeshGmsh")
mesh_obj.Shape = tube_obj
mesh_obj.ElementDimension = "2D"         # Generate 2D shell elements
mesh_obj.CharacteristicLengthMax = 8.0  # mm
mesh_obj.CharacteristicLengthMin = 2.0  # mm
mesh_obj.ElementOrder = "2nd"
mesh_obj.SecondOrderLinear = True
doc.recompute()
analysis.addObject(mesh_obj)

# Run Gmsh
gmsh_mesh = GmshTools(mesh_obj)
gmsh_mesh.create_mesh()
doc.recompute()

# 6. Constraints — Fixed at top and bottom 1D circular edges
top_edge_name = ""
bottom_edge_name = ""

for i, edge in enumerate(tube_obj.Shape.Edges):
    edge_label = f"Edge{i+1}"
    z_center = edge.CenterOfMass.z
    if abs(z_center - height) < 1e-3:
        top_edge_name = edge_label
    elif abs(z_center - 0.0) < 1e-3:
        bottom_edge_name = edge_label

fixed = ObjectsFem.makeConstraintFixed(doc, "ConstraintFixed")
fixed.References = [(tube_obj, top_edge_name), (tube_obj, bottom_edge_name)]
analysis.addObject(fixed)

# 7. Gravity Load (Self weight)
force = ObjectsFem.makeConstraintSelfWeight(doc, "ConstraintSelfWeight")
force.GravityAcceleration = 9810.0  # mm/s^2
force.GravityDirection = App.Vector(0, 0, -1)
analysis.addObject(force)

# 8. Solver
solver = ObjectsFem.makeSolverCalculiXCcxTools(doc, "CalculiXccxTools")

# Enable 3D output expansion in CalculiX for visualization if supported
if hasattr(solver, "BeamShellResultOutput3D"):
    solver.BeamShellResultOutput3D = True

analysis.addObject(solver)
doc.recompute()

# 9. Run Solver
fea = ccxtools.FemToolsCcx(analysis=analysis, solver=solver)
fea.update_objects()
fea.setup_working_dir()
fea.setup_ccx()
message = fea.check_prerequisites()

if not message:
    fea.purge_results()
    fea.write_inp_file()
    fea.ccx_run()
    fea.load_results()
    print("Shell FEA analysis completed successfully.")
else:
    print("Prerequisites not met:", message)

doc.recompute()
doc.saveAs("tube_shell_fea.FCStd")
