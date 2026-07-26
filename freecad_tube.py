# type: ignore

# /Applications/FreeCAD.app/Contents/MacOS/FreeCAD

import FreeCAD as App
import Part
import ObjectsFem
import femtools.ccxtools as ccxtools
from femmesh.gmshtools import GmshTools

doc = App.newDocument("TubeFEA")

# 1. Geometry — Part module uses boolean cut (outer cylinder - inner cylinder)
outer_r = 10.0  # mm
inner_r = 5.0   # mm
height = 1000.0  # mm

outer_cyl = Part.makeCylinder(outer_r, height)
inner_cyl = Part.makeCylinder(inner_r, height)
tube_shape = outer_cyl.cut(inner_cyl)

tube_obj = doc.addObject("Part::Feature", "MyTube")
tube_obj.Shape = tube_shape
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

# 4. Mesh Generation (Gmsh via GmshTools API)
mesh_obj = ObjectsFem.makeMeshGmsh(doc, "FEMMeshGmsh")
mesh_obj.Shape = tube_obj
mesh_obj.CharacteristicLengthMax = 2.0  # mm
mesh_obj.CharacteristicLengthMin = 0.5  # mm
mesh_obj.ElementOrder = "2nd"
doc.recompute()
analysis.addObject(mesh_obj)

# Execute Gmsh calculation
gmsh_mesh = GmshTools(mesh_obj)
gmsh_mesh.create_mesh()
doc.recompute()

# 5. Constraints — Programmatically locate top and bottom annular end faces
top_face_name = ""
bottom_face_name = ""

for i, face in enumerate(tube_obj.Shape.Faces):
    face_label = f"Face{i+1}"
    z_center = face.CenterOfMass.z
    if abs(z_center - height) < 1e-3:
        top_face_name = face_label
    elif abs(z_center - 0.0) < 1e-3:
        bottom_face_name = face_label

fixed = ObjectsFem.makeConstraintFixed(doc, "ConstraintFixed")
fixed.References = [(tube_obj, top_face_name), (tube_obj, bottom_face_name)]
analysis.addObject(fixed)

# 6. Gravity Load (Self weight)
force = ObjectsFem.makeConstraintSelfWeight(doc, "ConstraintSelfWeight")
# mm/s^2 (Standard gravity acceleration in mm system)
force.GravityAcceleration = 9810.0
force.GravityDirection = App.Vector(0, 0, -1)
analysis.addObject(force)

# 7. Solver
solver = ObjectsFem.makeSolverCalculixCcxTools(doc, "CalculiXccxTools")
analysis.addObject(solver)
doc.recompute()

# 8. Run CalculiX Solver
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
    print("FEA analysis completed successfully.")
else:
    print("Prerequisites not met:", message)

doc.recompute()
# doc.saveAs("tube_fea.FCStd")
