import bpy
import math
import os
from mathutils import Vector

# Happy V2 generator
# Blender 4.x compatible. Generates a stylized mascot, rig, and animation actions.
# Output: exports/happy_v2.blend + exports/happy_v2.glb

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "exports")
os.makedirs(OUT, exist_ok=True)

# ---------- scene reset ----------
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.armatures, bpy.data.actions):
    pass

scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 72
scene.render.fps = 30

# ---------- materials ----------
def mat(name, rgb, rough=.55, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.roughness = rough
    m.metallic = metallic
    return m

M_BLUE = mat("Happy_Blue", (0.045, 0.52, 0.92), .38)
M_BLUE_DARK = mat("Happy_BlueDark", (0.018, 0.18, 0.34), .44)
M_CREAM = mat("Happy_Cream", (1.0, 0.78, 0.36), .52)
M_YELLOW = mat("Happy_Yellow", (1.0, 0.68, 0.08), .4)
M_PINK = mat("Happy_Pink", (1.0, 0.16, 0.46), .4)
M_WHITE = mat("Happy_White", (0.97, 0.97, 1.0), .32)
M_BLACK = mat("Happy_Black", (0.012, 0.014, 0.02), .3)
M_MOUTH = mat("Happy_Mouth", (0.18, 0.012, 0.025), .45)
M_TOOTH = mat("Happy_Tooth", (1.0, 0.96, 0.84), .28)
M_SOLE = mat("Happy_Sole", (0.05, 0.06, 0.08), .58)

# ---------- mesh helpers ----------
def smooth(obj):
    if obj.type == "MESH":
        for poly in obj.data.polygons:
            poly.use_smooth = True

def uv_sphere(name, loc, scale, material, segments=40, rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        location=loc
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    smooth(obj)
    return obj

def rounded_cube(name, loc, scale, material, bevel=.18):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    bevel_mod = obj.modifiers.new("SoftBevel", "BEVEL")
    bevel_mod.width = bevel
    bevel_mod.segments = 4
    smooth(obj)
    return obj

def cylinder_between(name, a, b, radius, material):
    a = Vector(a); b = Vector(b)
    mid = (a + b) * .5
    length = (b - a).length
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=length, location=mid)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    direction = b - a
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    smooth(obj)
    return obj

def cone(name, loc, radius1, radius2, depth, material, rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=radius1, radius2=radius2, depth=depth, location=loc, rotation=rotation)
    obj=bpy.context.object
    obj.name=name
    obj.data.materials.append(material)
    smooth(obj)
    return obj

meshes=[]

def add(obj):
    meshes.append(obj)
    return obj

# ---------- body design ----------
# Happy is intentionally readable as friendly at rest and creepy in motion.
add(uv_sphere("Torso", (0,0,3.55), (1.6,1.02,1.95), M_BLUE))
add(uv_sphere("Belly", (0,-.83,3.45), (1.08,.24,1.35), M_CREAM))
add(uv_sphere("ChestBadge", (0,-1.08,4.0), (.34,.10,.34), M_PINK))

# head + muzzle
add(uv_sphere("Head", (0,0,6.42), (1.82,1.48,1.62), M_CREAM))
add(uv_sphere("Muzzle", (0,-1.23,5.95), (1.03,.42,.63), M_YELLOW))
add(uv_sphere("Nose", (0,-1.62,6.18), (.28,.19,.22), M_BLACK))

# ears
add(uv_sphere("Ear_L", (-1.48,0,6.62), (.62,.42,.72), M_BLUE))
add(uv_sphere("Ear_R", (1.48,0,6.62), (.62,.42,.72), M_BLUE))
add(uv_sphere("EarInner_L", (-1.54,-.27,6.62), (.30,.12,.38), M_PINK))
add(uv_sphere("EarInner_R", (1.54,-.27,6.62), (.30,.12,.38), M_PINK))

# eyes
for sx,side in [(-1,"L"),(1,"R")]:
    add(uv_sphere(f"Eye_{side}", (.63*sx,-1.28,6.72), (.46,.18,.59), M_WHITE))
    add(uv_sphere(f"Pupil_{side}", (.63*sx,-1.46,6.72), (.18,.09,.25), M_BLACK))
    add(uv_sphere(f"EyeHighlight_{side}", (.57*sx,-1.54,6.83), (.065,.04,.08), M_WHITE, 20, 12))
    brow=add(rounded_cube(f"Brow_{side}", (.63*sx,-1.43,7.38), (.46,.07,.11), M_BLUE_DARK, .08))
    brow.rotation_euler[1]=math.radians(-10*sx)

# mouth interior and jaw
mouth=add(uv_sphere("MouthInterior", (0,-1.50,5.72), (.74,.12,.38), M_MOUTH))
jaw=add(uv_sphere("Jaw", (0,-1.28,5.46), (.88,.34,.36), M_YELLOW))
# simple teeth line
for i,x in enumerate((-0.42,-0.14,0.14,0.42)):
    tooth=add(cone(f"Tooth_{i+1}", (x,-1.65,5.82), .09,.045,.24,M_TOOTH,(math.radians(90),0,0)))

# limbs - segmented for better silhouette
for sx,side in [(-1,"L"),(1,"R")]:
    add(uv_sphere(f"Shoulder_{side}", (1.57*sx,0,4.25), (.52,.52,.62), M_BLUE))
    add(cylinder_between(f"UpperArm_{side}", (1.55*sx,0,4.18),(2.12*sx,-.04,3.18), .34,M_BLUE))
    add(uv_sphere(f"Elbow_{side}", (2.12*sx,-.04,3.12), (.40,.40,.40), M_BLUE))
    add(cylinder_between(f"Forearm_{side}", (2.12*sx,-.04,3.10),(2.28*sx,-.12,2.18), .31,M_BLUE))
    add(uv_sphere(f"Palm_{side}", (2.28*sx,-.12,1.87), (.46,.36,.48), M_YELLOW))
    # chunky four-finger glove
    for fi,off in enumerate((-0.27,-0.09,0.09,0.27)):
        add(uv_sphere(f"Finger_{side}_{fi+1}", (2.28*sx+off*sx,-.38,1.64), (.13,.15,.30), M_YELLOW, 24, 14))

for sx,side in [(-1,"L"),(1,"R")]:
    add(uv_sphere(f"Hip_{side}", (.67*sx,0,2.05), (.63,.62,.67), M_BLUE_DARK))
    add(cylinder_between(f"Thigh_{side}", (.67*sx,0,2.02),(.72*sx,.02,.92), .45,M_BLUE_DARK))
    add(uv_sphere(f"Knee_{side}", (.72*sx,.02,.78), (.46,.46,.42), M_BLUE_DARK))
    add(cylinder_between(f"Shin_{side}", (.72*sx,.02,.72),(.74*sx,-.08,-.22), .40,M_BLUE_DARK))
    add(uv_sphere(f"Shoe_{side}", (.74*sx,-.38,-.42), (.72,1.02,.45), M_PINK))
    sole=add(rounded_cube(f"Sole_{side}", (.74*sx,-.45,-.75), (.72,.91,.11), M_SOLE,.08))

# tuft/horns to make silhouette distinctive
for i,x in enumerate((-0.38,0,0.38)):
    tuft=add(cone(f"Tuft_{i+1}", (x,0,8.02), .23,.02,.75,M_BLUE,(0,0,math.radians(x*35))))

# ---------- armature ----------
bpy.ops.object.armature_add(enter_editmode=True, location=(0,0,0))
arm=bpy.context.object
arm.name="HappyRig"
arm.data.name="HappyRigData"

edit=arm.data.edit_bones
# remove default and rebuild
for b in list(edit):
    edit.remove(b)

def bone(name, head, tail, parent=None, use_connect=False):
    b=edit.new(name)
    b.head=head; b.tail=tail
    if parent:
        b.parent=parent
        b.use_connect=use_connect
    return b

root=bone("Root",(0,0,-.85),(0,0,.05))
pelvis=bone("Pelvis",(0,0,.05),(0,0,1.9),root)
spine=bone("Spine",(0,0,1.9),(0,0,3.8),pelvis,True)
chest=bone("Chest",(0,0,3.8),(0,0,5.05),spine,True)
neck=bone("Neck",(0,0,5.05),(0,0,5.85),chest,True)
head_b=bone("Head",(0,0,5.85),(0,0,7.25),neck,True)
jaw_b=bone("Jaw",(0,-.1,5.72),(0,-1.05,5.36),head_b)
eye_l=bone("Eye_L",(-.63,-1.10,6.72),(-.63,-1.52,6.72),head_b)
eye_r=bone("Eye_R",(.63,-1.10,6.72),(.63,-1.52,6.72),head_b)

for sx,side in [(-1,"L"),(1,"R")]:
    clav=bone(f"Clavicle_{side}",(.35*sx,0,4.75),(1.25*sx,0,4.45),chest)
    upper=bone(f"UpperArm_{side}",(1.25*sx,0,4.45),(2.10*sx,-.03,3.18),clav,True)
    fore=bone(f"Forearm_{side}",(2.10*sx,-.03,3.18),(2.28*sx,-.12,2.10),upper,True)
    hand=bone(f"Hand_{side}",(2.28*sx,-.12,2.10),(2.28*sx,-.18,1.48),fore,True)
    thigh=bone(f"Thigh_{side}",(.62*sx,0,1.95),(.72*sx,.02,.78),pelvis)
    shin=bone(f"Shin_{side}",(.72*sx,.02,.78),(.74*sx,-.08,-.22),thigh,True)
    foot=bone(f"Foot_{side}",(.74*sx,-.08,-.22),(.74*sx,-.90,-.55),shin,True)

bpy.ops.object.mode_set(mode="OBJECT")

# ---------- bind ----------
# Join main deformable meshes to a single skinned mesh; keep tiny highlights/teeth included.
bpy.ops.object.select_all(action="DESELECT")
for obj in meshes:
    obj.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
bpy.ops.object.join()
body_mesh=bpy.context.object
body_mesh.name="HappyMesh"

# Apply modifiers for reliable export.
for mod in list(body_mesh.modifiers):
    try:
        bpy.context.view_layer.objects.active=body_mesh
        bpy.ops.object.modifier_apply(modifier=mod.name)
    except Exception:
        pass

body_mesh.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active=arm
try:
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
except Exception as exc:
    print("Automatic weights warning:", exc)
    arm_mod=body_mesh.modifiers.new("Armature","ARMATURE")
    arm_mod.object=arm

# ---------- skin weight cleanup ----------
# Roblox/glTF skinning is happiest with <= 4 joint influences per vertex.
# Automatic weights can assign more than four, so clamp and normalize before export.
bpy.context.view_layer.objects.active = body_mesh
body_mesh.select_set(True)
arm.select_set(False)
try:
    bpy.ops.object.mode_set(mode="OBJECT")
except Exception:
    pass

try:
    bpy.ops.object.vertex_group_limit_total(limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
except Exception as exc:
    print("Weight cleanup warning:", exc)

# ---------- animation helpers ----------
# Blender does not allocate animation_data until explicitly requested.
# Create it once before any keyframe helper assigns an action.
arm.animation_data_create()

def set_rot(pb, xyz_deg):
    pb.rotation_mode="XYZ"
    pb.rotation_euler=[math.radians(v) for v in xyz_deg]

def set_loc(pb, xyz):
    pb.location=xyz

def key_rot(action, frame, bone_name, xyz_deg):
    pb=arm.pose.bones.get(bone_name)
    if not pb: return
    arm.animation_data.action=action
    set_rot(pb,xyz_deg)
    pb.keyframe_insert(data_path="rotation_euler",frame=frame)

def key_loc(action, frame, bone_name, xyz):
    pb=arm.pose.bones.get(bone_name)
    if not pb: return
    arm.animation_data.action=action
    set_loc(pb,xyz)
    pb.keyframe_insert(data_path="location",frame=frame)

def action(name,start,end,loop=False):
    a=bpy.data.actions.new(name)
    a.frame_range=(start,end)
    a["Loop"]=loop
    return a

# Idle: breathing, tiny head drift
a=action("Happy_Idle",1,60,True)
for fr,val in [(1,0),(30,3),(60,0)]:
    key_rot(a,fr,"Chest",(val,0,0))
for fr,val in [(1,-3),(30,3),(60,-3)]:
    key_rot(a,fr,"Head",(0,val,0))
for fr,val in [(1,-8),(30,-3),(60,-8)]:
    key_rot(a,fr,"UpperArm_L",(val,0,-7))
    key_rot(a,fr,"UpperArm_R",(val,0,7))

# Walk
a=action("Happy_Walk",1,36,True)
for fr,phase in [(1,1),(10,-1),(19,1),(28,-1),(36,1)]:
    key_rot(a,fr,"Thigh_L",(30*phase,0,0)); key_rot(a,fr,"Thigh_R",(-30*phase,0,0))
    key_rot(a,fr,"Shin_L",(-22*max(phase,0),0,0)); key_rot(a,fr,"Shin_R",(-22*max(-phase,0),0,0))
    key_rot(a,fr,"UpperArm_L",(-24*phase,0,-8)); key_rot(a,fr,"UpperArm_R",(24*phase,0,8))
    key_rot(a,fr,"Chest",(0,0,3*phase))

# Run: hunched, aggressive
a=action("Happy_Run",1,24,True)
for fr,phase in [(1,1),(7,-1),(13,1),(19,-1),(24,1)]:
    key_rot(a,fr,"Chest",(13,0,5*phase))
    key_rot(a,fr,"Head",(-8,0,-4*phase))
    key_rot(a,fr,"Thigh_L",(46*phase,0,0)); key_rot(a,fr,"Thigh_R",(-46*phase,0,0))
    key_rot(a,fr,"Shin_L",(-38 if phase>0 else 8,0,0)); key_rot(a,fr,"Shin_R",(-38 if phase<0 else 8,0,0))
    key_rot(a,fr,"UpperArm_L",(-42*phase,0,-12)); key_rot(a,fr,"UpperArm_R",(42*phase,0,12))

# Crawl: intentionally unnatural
a=action("Happy_Crawl",1,32,True)
for fr,phase in [(1,1),(9,-1),(17,1),(25,-1),(32,1)]:
    key_rot(a,fr,"Chest",(68,0,4*phase))
    key_rot(a,fr,"Neck",(-38,0,0))
    key_rot(a,fr,"Head",(-24,0,-6*phase))
    key_rot(a,fr,"UpperArm_L",(65+20*phase,0,-24)); key_rot(a,fr,"UpperArm_R",(65-20*phase,0,24))
    key_rot(a,fr,"Thigh_L",(-42*phase,0,-12)); key_rot(a,fr,"Thigh_R",(42*phase,0,12))

# Lunge
a=action("Happy_Lunge",1,22,False)
key_rot(a,1,"Chest",(8,0,0)); key_rot(a,1,"Head",(0,0,0))
key_loc(a,1,"Root",(0,0,0))
key_rot(a,8,"Chest",(30,0,0)); key_rot(a,8,"UpperArm_L",(-85,0,-20)); key_rot(a,8,"UpperArm_R",(-85,0,20))
key_loc(a,8,"Root",(0,-.5,.15))
key_rot(a,14,"Chest",(48,0,0)); key_rot(a,14,"Head",(-18,0,0))
key_loc(a,14,"Root",(0,-1.5,.35))
key_rot(a,22,"Chest",(10,0,0)); key_loc(a,22,"Root",(0,-.2,0))

# Roar / jaw animation
a=action("Happy_Roar",1,42,False)
key_rot(a,1,"Jaw",(0,0,0)); key_rot(a,8,"Jaw",(35,0,0)); key_rot(a,24,"Jaw",(50,0,0)); key_rot(a,42,"Jaw",(0,0,0))
key_rot(a,8,"Head",(-10,0,0)); key_rot(a,24,"Head",(-22,0,0)); key_rot(a,42,"Head",(0,0,0))

# Wall peek
a=action("Happy_WallPeek",1,48,False)
key_loc(a,1,"Root",(0,0,0)); key_rot(a,1,"Head",(0,0,0))
key_loc(a,16,"Root",(.55,0,0)); key_rot(a,16,"Spine",(0,0,-18)); key_rot(a,16,"Head",(0,18,-12))
key_loc(a,34,"Root",(.75,0,0)); key_rot(a,34,"Head",(0,26,-15))
key_loc(a,48,"Root",(0,0,0)); key_rot(a,48,"Spine",(0,0,0)); key_rot(a,48,"Head",(0,0,0))

# Ceiling crawl variant
a=action("Happy_CeilingCrawl",1,32,True)
for fr,phase in [(1,1),(9,-1),(17,1),(25,-1),(32,1)]:
    key_rot(a,fr,"Pelvis",(0,0,180))
    key_rot(a,fr,"UpperArm_L",(55+22*phase,0,-18)); key_rot(a,fr,"UpperArm_R",(55-22*phase,0,18))
    key_rot(a,fr,"Thigh_L",(-35*phase,0,-14)); key_rot(a,fr,"Thigh_R",(35*phase,0,14))
    key_rot(a,fr,"Head",(-12,0,8*phase))

# Jumpscare
a=action("Happy_Jumpscare",1,30,False)
key_loc(a,1,"Root",(0,0,0)); key_rot(a,1,"Jaw",(0,0,0))
key_loc(a,7,"Root",(0,-.25,.12)); key_rot(a,7,"Head",(-12,0,0)); key_rot(a,7,"Jaw",(15,0,0))
key_loc(a,14,"Root",(0,-2.15,.55)); key_rot(a,14,"Chest",(38,0,0)); key_rot(a,14,"Jaw",(52,0,0))
key_rot(a,14,"UpperArm_L",(-95,0,-18)); key_rot(a,14,"UpperArm_R",(-95,0,18))
key_loc(a,23,"Root",(0,-3.0,.75)); key_rot(a,23,"Head",(-25,0,0)); key_rot(a,23,"Jaw",(58,0,0))
key_loc(a,30,"Root",(0,-3.1,.8))

# Reset pose to neutral before stashing/exporting so the .blend opens upright.
for pb in arm.pose.bones:
    pb.rotation_mode = "XYZ"
    pb.rotation_euler = (0,0,0)
    pb.location = (0,0,0)
    pb.scale = (1,1,1)

# Keep all actions associated with rig using NLA stashes so GLTF exports them.
arm.animation_data_create()
for a in list(bpy.data.actions):
    track=arm.animation_data.nla_tracks.new()
    track.name=a.name
    strip=track.strips.new(a.name,int(a.frame_range[0]),a)
    strip.action_frame_start=a.frame_range[0]
    strip.action_frame_end=a.frame_range[1]

# Set a neutral action and evaluate frame 1 before saving/export.
arm.animation_data.action=bpy.data.actions.get("Happy_Idle")
scene.frame_set(1)
bpy.context.view_layer.update()

# ---------- floor/reference presentation ----------
bpy.ops.mesh.primitive_plane_add(size=30, location=(0,0,-.9))
floor=bpy.context.object
floor.name="PreviewFloor"
floor.data.materials.append(mat("PreviewFloorMat",(0.035,.04,.055),.85))
floor.hide_render=True
floor.hide_set(True)

# ---------- save + export ----------
blend_path=os.path.join(OUT,"happy_v2.blend")
glb_path=os.path.join(OUT,"happy_v2.glb")

bpy.ops.wm.save_as_mainfile(filepath=blend_path)

# Export only Happy mesh + rig, not preview floor.
bpy.ops.object.select_all(action="DESELECT")
body_mesh.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active=arm

bpy.ops.export_scene.gltf(
    filepath=glb_path,
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_skins=True,
    export_morph=False
)

print("Happy V2 generated:")
print(blend_path)
print(glb_path)
print("Actions:", [a.name for a in bpy.data.actions])
