import bpy, math, os
from mathutils import Vector

# Clear scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def add_material(name, color):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    return mat

cream = add_material("HappyCream", (0.95,0.82,0.45))
blue = add_material("HappyBlue", (0.05,0.65,0.9))
dark = add_material("HappyDark", (0.02,0.02,0.03))
red = add_material("Mouth", (0.5,0.01,0.02))

def sphere(name, loc, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale; o.data.materials.append(mat)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return o

def cube(name, loc, scale, mat, bevel=.2):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod=o.modifiers.new("SoftEdges","BEVEL"); mod.width=bevel; mod.segments=3
    o.data.materials.append(mat)
    return o

body = sphere("Body",(0,0,2.7),(1.5,1.0,2.0),blue)
head = sphere("Head",(0,0,5.8),(1.65,1.45,1.55),cream)
for x in (-0.6,0.6):
    sphere("Eye",(x,-1.25,6.1),(0.32,0.18,0.45),dark)
    sphere("Pupil",(x,-1.42,6.12),(0.11,0.07,0.18),cream)
cube("Mouth",(0,-1.37,5.38),(0.65,0.1,0.16),red,.08)
for x in (-1.75,1.75):
    sphere("Arm",(x,0,3.0),(0.42,0.42,1.8),blue)
for x in (-0.7,0.7):
    sphere("Leg",(x,0,0.7),(0.5,0.5,1.55),blue)

# Armature
bpy.ops.object.armature_add(enter_editmode=True, location=(0,0,0))
arm=bpy.context.object; arm.name="HappyRig"
edit=arm.data.edit_bones
root=edit[0]; root.name="Root"; root.head=(0,0,0); root.tail=(0,0,1)
spine=edit.new("Spine"); spine.head=(0,0,1); spine.tail=(0,0,4.7); spine.parent=root
neck=edit.new("Neck"); neck.head=(0,0,4.7); neck.tail=(0,0,5.6); neck.parent=spine
headb=edit.new("Head"); headb.head=(0,0,5.6); headb.tail=(0,0,6.7); headb.parent=neck
for side, sx in (("L",-1),("R",1)):
    upper=edit.new(f"UpperArm_{side}"); upper.head=(0.8*sx,0,4.2); upper.tail=(1.8*sx,0,3.5); upper.parent=spine
    lower=edit.new(f"LowerArm_{side}"); lower.head=upper.tail; lower.tail=(2.2*sx,0,2.4); lower.parent=upper
    thigh=edit.new(f"Thigh_{side}"); thigh.head=(0.55*sx,0,1.6); thigh.tail=(0.65*sx,0,0.6); thigh.parent=root
    shin=edit.new(f"Shin_{side}"); shin.head=thigh.tail; shin.tail=(0.7*sx,0,-0.4); shin.parent=thigh
bpy.ops.object.mode_set(mode='OBJECT')

# Parent visible meshes to armature automatically.
for o in [body,head]+[x for x in bpy.context.scene.objects if x.type=='MESH' and x not in (body,head)]:
    o.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active=arm
try:
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')
except:
    pass

# Simple authored actions; intended as a polished starting rig, not final mocap.
def make_action(name, frames, keys):
    action=bpy.data.actions.new(name)
    arm.animation_data_create(); arm.animation_data.action=action
    for frame, bone_name, rot in keys:
        pb=arm.pose.bones.get(bone_name)
        if not pb: continue
        pb.rotation_mode='XYZ'
        pb.rotation_euler=rot
        pb.keyframe_insert(data_path='rotation_euler', frame=frame)
    action.frame_range=(1,frames)

make_action("Happy_Idle",48,[
    (1,"Spine",(0,0,0)),(24,"Spine",(math.radians(3),0,0)),(48,"Spine",(0,0,0)),
    (1,"Head",(0,0,0)),(24,"Head",(0,0,math.radians(4))),(48,"Head",(0,0,0)),
])
make_action("Happy_Run",24,[
    (1,"UpperArm_L",(math.radians(35),0,0)),(1,"UpperArm_R",(math.radians(-35),0,0)),
    (12,"UpperArm_L",(math.radians(-35),0,0)),(12,"UpperArm_R",(math.radians(35),0,0)),
    (24,"UpperArm_L",(math.radians(35),0,0)),(24,"UpperArm_R",(math.radians(-35),0,0)),
])

out=os.path.abspath(os.path.join(os.path.dirname(__file__),"../exports"))
os.makedirs(out,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,"happy.blend"))
bpy.ops.export_scene.gltf(filepath=os.path.join(out,"happy.glb"), export_format='GLB', export_animations=True)
print("Exported", os.path.join(out,"happy.glb"))
