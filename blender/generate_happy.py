import bpy
import math
import os
from mathutils import Vector

"""
Happy V3 — deterministic Roblox mascot generator.

Why V3 exists:
- V1/V2 used automatic weights, which caused face/body pieces to deform onto the wrong bones.
- V2 also stashed every action into active NLA tracks, so Blender blended multiple animations at once.
- V3 uses exact one-bone rigid weights per stylized body part and NEVER blends animation actions.
- Each action is exported independently for inspection/import.

Outputs:
  exports/happy_v3.blend
  exports/happy_v3.glb
  exports/happy_animations/Happy_Idle.glb
  exports/happy_animations/Happy_Walk.glb
  ...etc
"""

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "exports")
ANIM_OUT = os.path.join(OUT, "happy_animations")
os.makedirs(OUT, exist_ok=True)
os.makedirs(ANIM_OUT, exist_ok=True)

scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 90
scene.render.fps = 30

# ---------------------------------------------------------------------------
# Scene reset
# ---------------------------------------------------------------------------
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

# Remove old generated actions so repeated runs do not accumulate clips.
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)

# ---------------------------------------------------------------------------
# Materials
# ---------------------------------------------------------------------------
def make_mat(name, rgb, roughness=.5, metallic=0.0):
    material = bpy.data.materials.new(name=name)
    material.diffuse_color = (*rgb, 1.0)
    material.roughness = roughness
    material.metallic = metallic
    return material

BLUE = make_mat("Happy_Blue", (0.035, 0.48, 0.92), .36)
BLUE_DARK = make_mat("Happy_BlueDark", (0.018, 0.16, 0.32), .44)
CREAM = make_mat("Happy_Cream", (0.98, 0.78, 0.39), .50)
YELLOW = make_mat("Happy_Yellow", (1.0, 0.66, 0.08), .40)
PINK = make_mat("Happy_Pink", (1.0, 0.13, 0.43), .40)
WHITE = make_mat("Happy_White", (0.97, 0.98, 1.0), .30)
BLACK = make_mat("Happy_Black", (0.008, 0.010, 0.016), .28)
MOUTH = make_mat("Happy_Mouth", (0.17, 0.008, 0.02), .46)
TOOTH = make_mat("Happy_Tooth", (1.0, 0.96, 0.84), .26)
SOLE = make_mat("Happy_Sole", (0.045, 0.05, 0.065), .60)

# ---------------------------------------------------------------------------
# Mesh helpers
# ---------------------------------------------------------------------------
parts = []  # (object, controlling_bone)

def smooth(obj):
    if obj.type == "MESH":
        for poly in obj.data.polygons:
            poly.use_smooth = True

def sphere(name, loc, scale, material, bone, segments=36, rings=22):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        location=loc,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smooth(obj)
    parts.append((obj, bone))
    return obj

def rounded_cube(name, loc, scale, material, bone, bevel=.14):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("SoftBevel", "BEVEL")
    modifier.width = bevel
    modifier.segments = 3
    parts.append((obj, bone))
    return obj

def cylinder_between(name, a, b, radius, material, bone):
    a = Vector(a)
    b = Vector(b)
    direction = b - a
    midpoint = (a + b) * .5
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=28,
        radius=radius,
        depth=direction.length,
        location=midpoint,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    obj.data.materials.append(material)
    smooth(obj)
    parts.append((obj, bone))
    return obj

def cone(name, loc, radius1, radius2, depth, material, bone, rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cone_add(
        vertices=28,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=loc,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    smooth(obj)
    parts.append((obj, bone))
    return obj

# ---------------------------------------------------------------------------
# Happy visual design
# ---------------------------------------------------------------------------
# Centered at X=0, facing Blender -Y. Feet rest around Z=0.

# torso / chest
sphere("Torso", (0,0,3.55), (1.58,1.03,1.88), BLUE, "Chest")
sphere("LowerTorso", (0,0,2.55), (1.30,.91,1.06), BLUE_DARK, "Spine")
sphere("Belly", (0,-.88,3.48), (1.04,.22,1.28), CREAM, "Chest")
sphere("ChestBadge", (0,-1.10,4.08), (.32,.09,.32), PINK, "Chest", 24, 14)

# head
sphere("Head", (0,0,6.38), (1.78,1.45,1.56), CREAM, "Head")
sphere("Muzzle", (0,-1.22,5.96), (1.00,.40,.60), YELLOW, "Head")
sphere("Nose", (0,-1.58,6.19), (.27,.17,.21), BLACK, "Head", 28, 16)

# ears
sphere("Ear_L", (-1.45,0,6.63), (.58,.39,.67), BLUE, "Head")
sphere("Ear_R", (1.45,0,6.63), (.58,.39,.67), BLUE, "Head")
sphere("EarInner_L", (-1.49,-.26,6.63), (.29,.10,.35), PINK, "Head", 24, 14)
sphere("EarInner_R", (1.49,-.26,6.63), (.29,.10,.35), PINK, "Head", 24, 14)

# eyes are rigidly controlled by individual eye bones.
for sx, side in [(-1,"L"), (1,"R")]:
    eye_bone = f"Eye_{side}"
    sphere(f"Eye_{side}", (.61*sx,-1.27,6.72), (.44,.17,.56), WHITE, eye_bone)
    sphere(f"Pupil_{side}", (.61*sx,-1.43,6.71), (.17,.065,.24), BLACK, eye_bone, 24, 14)
    sphere(f"EyeHighlight_{side}", (.55*sx,-1.49,6.82), (.06,.03,.075), WHITE, eye_bone, 18, 10)
    brow = rounded_cube(
        f"Brow_{side}",
        (.61*sx,-1.39,7.35),
        (.44,.055,.095),
        BLUE_DARK,
        "Head",
        .07,
    )
    brow.rotation_euler[1] = math.radians(-8*sx)

# mouth/jaw. Lower jaw/teeth move together.
sphere("MouthInterior", (0,-1.43,5.68), (.70,.10,.34), MOUTH, "Jaw")
sphere("Jaw", (0,-1.22,5.45), (.84,.31,.33), YELLOW, "Jaw")
for i, x in enumerate((-0.39,-0.13,0.13,0.39)):
    cone(
        f"LowerTooth_{i+1}",
        (x,-1.55,5.74),
        .082,.035,.22,
        TOOTH,
        "Jaw",
        (math.radians(90),0,0),
    )

# distinctive top tuft
for i, x in enumerate((-0.38, 0, 0.38)):
    cone(
        f"Tuft_{i+1}",
        (x,0,8.00),
        .22,.025,.70,
        BLUE,
        "Head",
        (0,math.radians(x*12),math.radians(x*28)),
    )

# arms
for sx, side in [(-1,"L"), (1,"R")]:
    sphere(f"Shoulder_{side}", (1.48*sx,0,4.28), (.48,.48,.56), BLUE, f"UpperArm_{side}")
    cylinder_between(
        f"UpperArmMesh_{side}",
        (1.48*sx,0,4.20),
        (2.05*sx,-.02,3.24),
        .33, BLUE, f"UpperArm_{side}",
    )
    sphere(f"Elbow_{side}", (2.05*sx,-.02,3.17), (.37,.37,.37), BLUE, f"Forearm_{side}")
    cylinder_between(
        f"ForearmMesh_{side}",
        (2.05*sx,-.02,3.11),
        (2.20*sx,-.11,2.20),
        .30, BLUE, f"Forearm_{side}",
    )
    sphere(f"Palm_{side}", (2.20*sx,-.11,1.91), (.43,.34,.45), YELLOW, f"Hand_{side}")
    for fi, off in enumerate((-0.25,-0.08,0.09,0.25)):
        sphere(
            f"Finger_{side}_{fi+1}",
            (2.20*sx + off*sx,-.34,1.67),
            (.115,.135,.28),
            YELLOW,
            f"Hand_{side}",
            20,12,
        )

# legs
for sx, side in [(-1,"L"), (1,"R")]:
    sphere(f"Hip_{side}", (.63*sx,0,2.04), (.59,.58,.62), BLUE_DARK, f"Thigh_{side}")
    cylinder_between(
        f"ThighMesh_{side}",
        (.63*sx,0,2.00),
        (.68*sx,.01,.92),
        .42, BLUE_DARK, f"Thigh_{side}",
    )
    sphere(f"Knee_{side}", (.68*sx,.01,.79), (.43,.43,.40), BLUE_DARK, f"Shin_{side}")
    cylinder_between(
        f"ShinMesh_{side}",
        (.68*sx,.01,.73),
        (.70*sx,-.07,-.15),
        .37, BLUE_DARK, f"Shin_{side}",
    )
    sphere(f"Shoe_{side}", (.70*sx,-.34,-.34), (.68,.92,.42), PINK, f"Foot_{side}")
    rounded_cube(f"Sole_{side}", (.70*sx,-.42,-.65), (.68,.84,.10), SOLE, f"Foot_{side}", .07)

# ---------------------------------------------------------------------------
# Rig
# ---------------------------------------------------------------------------
bpy.ops.object.armature_add(enter_editmode=True, location=(0,0,0))
arm = bpy.context.object
arm.name = "HappyRig"
arm.data.name = "HappyRigData"
edit = arm.data.edit_bones
for old in list(edit):
    edit.remove(old)

def bone(name, head, tail, parent=None, connected=False):
    b = edit.new(name)
    b.head = head
    b.tail = tail
    if parent:
        b.parent = parent
        b.use_connect = connected
    return b

root = bone("Root", (0,0,-.70), (0,0,.10))
pelvis = bone("Pelvis", (0,0,.10), (0,0,1.75), root)
spine = bone("Spine", (0,0,1.75), (0,0,3.25), pelvis, True)
chest = bone("Chest", (0,0,3.25), (0,0,4.95), spine, True)
neck = bone("Neck", (0,0,4.95), (0,0,5.72), chest, True)
head_bone = bone("Head", (0,0,5.72), (0,0,7.35), neck, True)
jaw_bone = bone("Jaw", (0,-.18,5.78), (0,-1.05,5.42), head_bone)
eye_l = bone("Eye_L", (-.61,-1.05,6.72), (-.61,-1.48,6.72), head_bone)
eye_r = bone("Eye_R", (.61,-1.05,6.72), (.61,-1.48,6.72), head_bone)

for sx, side in [(-1,"L"), (1,"R")]:
    clav = bone(f"Clavicle_{side}", (.30*sx,0,4.70), (1.18*sx,0,4.40), chest)
    upper = bone(f"UpperArm_{side}", (1.18*sx,0,4.40), (2.03*sx,-.02,3.20), clav, True)
    fore = bone(f"Forearm_{side}", (2.03*sx,-.02,3.20), (2.20*sx,-.11,2.12), upper, True)
    hand = bone(f"Hand_{side}", (2.20*sx,-.11,2.12), (2.20*sx,-.18,1.48), fore, True)
    thigh = bone(f"Thigh_{side}", (.58*sx,0,1.88), (.68*sx,.01,.80), pelvis)
    shin = bone(f"Shin_{side}", (.68*sx,.01,.80), (.70*sx,-.07,-.15), thigh, True)
    foot = bone(f"Foot_{side}", (.70*sx,-.07,-.15), (.70*sx,-.78,-.48), shin, True)

bpy.ops.object.mode_set(mode="OBJECT")

# ---------------------------------------------------------------------------
# Deterministic skinning
# ---------------------------------------------------------------------------
# Each stylized mesh part gets exactly ONE controlling bone at weight 1.0.
# This completely avoids the V1/V2 automatic-weight deformation problem.
for obj, bone_name in parts:
    # Apply object-level geometry modifiers before joining.
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for modifier in list(obj.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        except Exception:
            pass
    try:
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    except Exception:
        pass

    group = obj.vertex_groups.new(name=bone_name)
    indices = [v.index for v in obj.data.vertices]
    if indices:
        group.add(indices, 1.0, "REPLACE")
    obj.select_set(False)

# Join all weighted pieces into one MeshPart-style skinned mesh.
bpy.ops.object.select_all(action="DESELECT")
for obj, _ in parts:
    obj.select_set(True)

bpy.context.view_layer.objects.active = parts[0][0]
bpy.ops.object.join()
happy_mesh = bpy.context.object
happy_mesh.name = "HappyMesh"

# Bake joined object transform to identity at world origin.
bpy.context.view_layer.objects.active = happy_mesh
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

armature_modifier = happy_mesh.modifiers.new("HappyRig", "ARMATURE")
armature_modifier.object = arm
happy_mesh.parent = arm

# ---------------------------------------------------------------------------
# Animation authoring
# ---------------------------------------------------------------------------
arm.animation_data_create()

def reset_pose():
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (0.0,0.0,0.0)
        pb.location = (0.0,0.0,0.0)
        pb.scale = (1.0,1.0,1.0)
    bpy.context.view_layer.update()

def new_action(name, start, end, loop=True):
    reset_pose()
    action = bpy.data.actions.new(name=name)
    action.use_fake_user = True
    action.frame_range = (start,end)
    action["Loop"] = bool(loop)
    arm.animation_data.action = action
    scene.frame_start = start
    scene.frame_end = end
    scene.frame_set(start)
    return action

def key_rot(action, frame, bone_name, xyz_deg):
    pb = arm.pose.bones.get(bone_name)
    if not pb:
        return
    arm.animation_data.action = action
    pb.rotation_mode = "XYZ"
    pb.rotation_euler = tuple(math.radians(v) for v in xyz_deg)
    pb.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)

def key_loc(action, frame, bone_name, xyz):
    pb = arm.pose.bones.get(bone_name)
    if not pb:
        return
    arm.animation_data.action = action
    pb.location = xyz
    pb.keyframe_insert(data_path="location", frame=frame, group=bone_name)

def finalize(action, interpolation="BEZIER"):
    for curve in action.fcurves:
        for point in curve.keyframe_points:
            point.interpolation = interpolation

# Idle — subtle breathing, eye/head micro-motion.
a = new_action("Happy_Idle", 1, 60, True)
for frame, chest_x, head_z in [(1,0,-2),(30,3,2),(60,0,-2)]:
    key_rot(a,frame,"Chest",(chest_x,0,0))
    key_rot(a,frame,"Head",(0,0,head_z))
    key_rot(a,frame,"UpperArm_L",(-7,0,-5))
    key_rot(a,frame,"UpperArm_R",(-7,0,5))
for frame, eye_y in [(1,-3),(30,3),(60,-3)]:
    key_rot(a,frame,"Eye_L",(0,eye_y,0))
    key_rot(a,frame,"Eye_R",(0,eye_y,0))
finalize(a,"BEZIER")

# Walk — readable mascot strut.
a = new_action("Happy_Walk", 1, 40, True)
walk_keys = [(1,1),(11,-1),(21,1),(31,-1),(40,1)]
for frame, phase in walk_keys:
    key_rot(a,frame,"Thigh_L",(27*phase,0,0))
    key_rot(a,frame,"Thigh_R",(-27*phase,0,0))
    key_rot(a,frame,"Shin_L",(-22 if phase>0 else 6,0,0))
    key_rot(a,frame,"Shin_R",(-22 if phase<0 else 6,0,0))
    key_rot(a,frame,"Foot_L",(8 if phase>0 else -5,0,0))
    key_rot(a,frame,"Foot_R",(8 if phase<0 else -5,0,0))
    key_rot(a,frame,"UpperArm_L",(-22*phase,0,-6))
    key_rot(a,frame,"UpperArm_R",(22*phase,0,6))
    key_rot(a,frame,"Chest",(0,0,2.5*phase))
    key_rot(a,frame,"Head",(0,0,-1.5*phase))
finalize(a,"BEZIER")

# Run — faster, forward hunched, aggressive.
a = new_action("Happy_Run", 1, 24, True)
for frame, phase in [(1,1),(7,-1),(13,1),(19,-1),(24,1)]:
    key_rot(a,frame,"Chest",(14,0,4*phase))
    key_rot(a,frame,"Head",(-8,0,-3*phase))
    key_rot(a,frame,"Thigh_L",(43*phase,0,0))
    key_rot(a,frame,"Thigh_R",(-43*phase,0,0))
    key_rot(a,frame,"Shin_L",(-36 if phase>0 else 10,0,0))
    key_rot(a,frame,"Shin_R",(-36 if phase<0 else 10,0,0))
    key_rot(a,frame,"UpperArm_L",(-40*phase,0,-10))
    key_rot(a,frame,"UpperArm_R",(40*phase,0,10))
    key_loc(a,frame,"Pelvis",(0,0,.06 if phase>0 else -.02))
finalize(a,"BEZIER")

# Crawl — creepy quadruped-style pose, but NOT world-inverted.
a = new_action("Happy_Crawl", 1, 32, True)
for frame, phase in [(1,1),(9,-1),(17,1),(25,-1),(32,1)]:
    key_rot(a,frame,"Pelvis",(28,0,0))
    key_rot(a,frame,"Spine",(30,0,0))
    key_rot(a,frame,"Chest",(28,0,3*phase))
    key_rot(a,frame,"Neck",(-34,0,0))
    key_rot(a,frame,"Head",(-22,0,-5*phase))
    key_rot(a,frame,"UpperArm_L",(62+17*phase,0,-18))
    key_rot(a,frame,"UpperArm_R",(62-17*phase,0,18))
    key_rot(a,frame,"Forearm_L",(-40,0,0))
    key_rot(a,frame,"Forearm_R",(-40,0,0))
    key_rot(a,frame,"Thigh_L",(-30*phase,0,-9))
    key_rot(a,frame,"Thigh_R",(30*phase,0,9))
    key_rot(a,frame,"Shin_L",(38,0,0))
    key_rot(a,frame,"Shin_R",(38,0,0))
finalize(a,"BEZIER")

# Lunge — short anticipation -> attack.
a = new_action("Happy_Lunge", 1, 24, False)
key_rot(a,1,"Chest",(5,0,0))
key_loc(a,1,"Root",(0,0,0))
key_rot(a,7,"Chest",(-10,0,0))
key_rot(a,7,"UpperArm_L",(25,0,-10))
key_rot(a,7,"UpperArm_R",(25,0,10))
key_loc(a,7,"Root",(0,.12,-.04))
key_rot(a,13,"Chest",(35,0,0))
key_rot(a,13,"Head",(-16,0,0))
key_rot(a,13,"UpperArm_L",(-78,0,-18))
key_rot(a,13,"UpperArm_R",(-78,0,18))
key_loc(a,13,"Root",(0,-1.35,.35))
key_rot(a,18,"Jaw",(42,0,0))
key_loc(a,18,"Root",(0,-2.00,.48))
key_rot(a,24,"Chest",(8,0,0))
key_rot(a,24,"Jaw",(0,0,0))
finalize(a,"BEZIER")

# Roar — jaw + head/chest motion.
a = new_action("Happy_Roar", 1, 44, False)
key_rot(a,1,"Jaw",(0,0,0))
key_rot(a,1,"Head",(0,0,0))
key_rot(a,8,"Chest",(-6,0,0))
key_rot(a,8,"Head",(10,0,0))
key_rot(a,8,"Jaw",(18,0,0))
key_rot(a,18,"Chest",(12,0,0))
key_rot(a,18,"Head",(-20,0,0))
key_rot(a,18,"Jaw",(52,0,0))
key_rot(a,32,"Head",(-13,0,2))
key_rot(a,32,"Jaw",(45,0,0))
key_rot(a,44,"Chest",(0,0,0))
key_rot(a,44,"Head",(0,0,0))
key_rot(a,44,"Jaw",(0,0,0))
finalize(a,"BEZIER")

# Wall peek.
a = new_action("Happy_WallPeek", 1, 50, False)
key_loc(a,1,"Root",(0,0,0))
key_rot(a,1,"Spine",(0,0,0))
key_rot(a,1,"Head",(0,0,0))
key_loc(a,14,"Root",(.30,0,0))
key_rot(a,14,"Spine",(0,0,-12))
key_rot(a,14,"Head",(0,18,-8))
key_loc(a,28,"Root",(.60,0,0))
key_rot(a,28,"Spine",(0,0,-20))
key_rot(a,28,"Head",(0,28,-14))
key_rot(a,28,"Eye_L",(0,8,0))
key_rot(a,28,"Eye_R",(0,8,0))
key_loc(a,40,"Root",(.60,0,0))
key_rot(a,40,"Head",(0,22,-12))
key_loc(a,50,"Root",(0,0,0))
key_rot(a,50,"Spine",(0,0,0))
key_rot(a,50,"Head",(0,0,0))
finalize(a,"BEZIER")

# Ceiling crawl: creepy inverted BODY pose without rotating world Root.
# In Roblox, the NPC controller can orient the whole model to a ceiling surface;
# this action provides the limb motion without corrupting the neutral rig.
a = new_action("Happy_CeilingCrawl", 1, 32, True)
for frame, phase in [(1,1),(9,-1),(17,1),(25,-1),(32,1)]:
    key_rot(a,frame,"Pelvis",(18,0,0))
    key_rot(a,frame,"Spine",(22,0,0))
    key_rot(a,frame,"Chest",(20,0,-4*phase))
    key_rot(a,frame,"Neck",(-28,0,0))
    key_rot(a,frame,"Head",(-18,0,5*phase))
    key_rot(a,frame,"UpperArm_L",(70+18*phase,0,-15))
    key_rot(a,frame,"UpperArm_R",(70-18*phase,0,15))
    key_rot(a,frame,"Forearm_L",(-52,0,0))
    key_rot(a,frame,"Forearm_R",(-52,0,0))
    key_rot(a,frame,"Thigh_L",(-28*phase,0,-10))
    key_rot(a,frame,"Thigh_R",(28*phase,0,10))
    key_rot(a,frame,"Shin_L",(48,0,0))
    key_rot(a,frame,"Shin_R",(48,0,0))
finalize(a,"BEZIER")

# Jumpscare.
a = new_action("Happy_Jumpscare", 1, 32, False)
key_loc(a,1,"Root",(0,0,0))
key_rot(a,1,"Jaw",(0,0,0))
key_rot(a,1,"Chest",(0,0,0))
key_loc(a,8,"Root",(0,.15,-.04))
key_rot(a,8,"Chest",(-12,0,0))
key_rot(a,8,"Head",(10,0,0))
key_rot(a,8,"Jaw",(10,0,0))
key_loc(a,14,"Root",(0,-1.65,.40))
key_rot(a,14,"Chest",(34,0,0))
key_rot(a,14,"Head",(-20,0,0))
key_rot(a,14,"Jaw",(55,0,0))
key_rot(a,14,"UpperArm_L",(-92,0,-20))
key_rot(a,14,"UpperArm_R",(-92,0,20))
key_loc(a,22,"Root",(0,-2.80,.72))
key_rot(a,22,"Head",(-28,0,0))
key_rot(a,22,"Jaw",(60,0,0))
key_rot(a,22,"Hand_L",(-18,0,0))
key_rot(a,22,"Hand_R",(-18,0,0))
key_loc(a,32,"Root",(0,-3.05,.78))
finalize(a,"BEZIER")

# Capture references before saving/export.
actions = {a.name: a for a in bpy.data.actions if a.name.startswith("Happy_")}

# ---------------------------------------------------------------------------
# Neutral saved state — no NLA tracks, only Idle active.
# ---------------------------------------------------------------------------
# V3 intentionally has ZERO NLA strips. This is the critical fix for the
# V2 "all animations blended at once" failure.
if arm.animation_data:
    for track in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(track)

reset_pose()
idle = actions["Happy_Idle"]
arm.animation_data.action = idle
scene.frame_start = int(idle.frame_range[0])
scene.frame_end = int(idle.frame_range[1])
scene.frame_set(1)
bpy.context.view_layer.update()

# Preview floor for Blender only.
bpy.ops.mesh.primitive_plane_add(size=24, location=(0,0,-.78))
preview_floor = bpy.context.object
preview_floor.name = "PreviewFloor"
preview_floor.data.materials.append(make_mat("PreviewFloorMat",(.035,.04,.055),.88))

# Save Blend with neutral/Idle visible.
blend_path = os.path.join(OUT, "happy_v3.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend_path)

# ---------------------------------------------------------------------------
# Export helpers
# ---------------------------------------------------------------------------
def select_export_objects():
    bpy.ops.object.select_all(action="DESELECT")
    happy_mesh.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm

def export_gltf(filepath, action):
    arm.animation_data.action = action
    scene.frame_start = int(action.frame_range[0])
    scene.frame_end = int(action.frame_range[1])
    scene.frame_set(int(action.frame_range[0]))
    bpy.context.view_layer.update()
    select_export_objects()

    kwargs = dict(
        filepath=filepath,
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_skins=True,
        export_morph=False,
        export_nla_strips=False,
    )

    # Keep compatibility across Blender 4.x versions.
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    if "export_anim_single_armature" in props:
        kwargs["export_anim_single_armature"] = True

    bpy.ops.export_scene.gltf(**kwargs)

# Main model export with Idle only.
main_glb = os.path.join(OUT, "happy_v3.glb")
export_gltf(main_glb, idle)

# Independent animation exports. No action can contaminate another.
for name, action in sorted(actions.items()):
    path = os.path.join(ANIM_OUT, f"{name}.glb")
    export_gltf(path, action)

# Return the .blend to neutral idle and save again after exports.
arm.animation_data.action = idle
scene.frame_start = int(idle.frame_range[0])
scene.frame_end = int(idle.frame_range[1])
scene.frame_set(1)
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=blend_path)

print("")
print("HAPPY V3 BUILD SUCCESS")
print("Blend:", blend_path)
print("Main GLB:", main_glb)
print("Animation GLBs:", ANIM_OUT)
print("Actions:", ", ".join(sorted(actions.keys())))
print("Skinning: deterministic single-bone weights (no automatic weights)")
print("NLA tracks:", len(arm.animation_data.nla_tracks))
