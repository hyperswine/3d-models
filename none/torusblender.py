import bpy
import bmesh
from math import radians, cos, sin

# Create the torus
bpy.ops.mesh.primitive_torus_add(
    align='WORLD', 
    major_segments=16, 
    minor_radius=4/10,  # (outer diameter - inner diameter) / 2
    major_radius=11/10,  # (outer diameter + inner diameter) / 2
    location=(0, 0, 0)
)

torus = bpy.context.object

# Create the armature
bpy.ops.object.armature_add(location=(0, 0, 0))
armature = bpy.context.object

# Switch to edit mode
bpy.context.view_layer.objects.active = armature
bpy.ops.object.mode_set(mode='EDIT')

# Rename the default bone to 'Root'
root_bone = armature.data.edit_bones['Bone']
root_bone.name = 'Root'

# Create the bones
bone_names = ['N', 'NW', 'W', 'SW', 'S', 'SE', 'E', 'NE']
for i, bone_name in enumerate(bone_names):
    bone = armature.data.edit_bones.new(bone_name)
    angle = radians(i * 45)
    bone.head = (4*1.75/10 * cos(angle), 4*1.75/10 * sin(angle), 0)
    bone.tail = (15/10 * cos(angle), 15/10 * sin(angle), 0)
    bone.parent = root_bone

# Switch back to object mode
bpy.ops.object.mode_set(mode='OBJECT')

# Parent the torus to the armature
torus.select_set(True)
armature.select_set(True)
bpy.context.view_layer.objects.active = armature
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
# Create the icosphere
bpy.ops.mesh.primitive_ico_sphere_add(location=(0, 0, 0))
icosphere = bpy.context.object

# Add a Shrinkwrap constraint to each bone
for bone in armature.pose.bones:
    if bone.name != 'Root':
        constraint = bone.constraints.new('SHRINKWRAP')
        constraint.target = icosphere
        constraint.shrinkwrap_type = 'PROJECT'
        constraint.project_axis = 'POS_Y'
