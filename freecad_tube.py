# type: ignore

# /Applications/FreeCAD.app/Contents/MacOS/FreeCAD

from femmesh.netgentools import NetgenTools  # module name varies by version
from femmesh.gmshtools import GmshTools
import FreeCAD as App
import Part
import ObjectsFem
from femmesh.gmshtools import GmshTools  # or use Netgen via task panel API
import femtools.ccxtools as ccxtools

doc = App.newDocument("TubeFEA")

# 1. Geometry — Part::Tube primitive is the easy path
# tube = doc.addObject("Part::Tube", "Tube")
# tube.OD = 25       # mm
# tube.ID = 22       # mm
# tube.Height = 1000  # mm
# doc.recompute()

# There is no Part::Tube

# Dimensions are in millimeters
outer_r = 10.0
inner_r = 5.0
height = 1000.0

tube_shape = Part.makeTube(outer_r, inner_r, height)

tube_obj = doc.addObject("Part::Feature", "MyTube")
tube_obj.Shape = tube_shape

# 2. Analysis container
analysis = ObjectsFem.makeAnalysis(doc, "Analysis")

# 3. Material
material = ObjectsFem.makeMaterialSolid(doc, "Aluminium")
mat = material.Material
mat["Name"] = "Aluminium-6061"
mat["YoungsModulus"] = "69000 MPa"
mat["PoissonRatio"] = "0.33"
mat["Density"] = "2700 kg/m^3"
material.Material = mat
analysis.addObject(material)

# 4. Mesh (Netgen)
mesh_obj = ObjectsFem.makeMeshNetgen(doc, "FEMMeshNetgen")
mesh_obj.Shape = tube
mesh_obj.MaxSize = 1.0      # your wall/3 rule of thumb
mesh_obj.MinSize = 0.0
mesh_obj.Fineness = "Moderate"
mesh_obj.SecondOrder = True
mesh_obj.Optimize = True
analysis.addObject(mesh_obj)
doc.recompute()

# Actually generate the mesh
mesh_obj.proxy.execute(mesh_obj)  # or run via GUI task panel equivalent
doc.recompute()

# 5. Constraints — fixed at both ends
fixed = ObjectsFem.makeConstraintFixed(doc, "ConstraintFixed")
fixed.References = [(tube, "Face1"), (tube, "Face2")]  # end faces — verify names
analysis.addObject(fixed)

# 6. Load — e.g. self weight
force = ObjectsFem.makeConstraintSelfWeight(doc, "ConstraintSelfWeight")
force.Gravity_z = -9810  # mm/s^2 if using mm units
analysis.addObject(force)

# 7. Solver
solver = ObjectsFem.makeSolverCalculixCcxTools(doc, "CalculiXccxTools")
analysis.addObject(solver)
doc.recompute()

# 8. Run
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
else:
    print("Prerequisites not met:", message)

doc.recompute()
doc.save("tube_fea.FCStd")
