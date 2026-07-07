"""
=============================================================================
  blender_retarget_explosive_to_mixamo.py  [v2 - Auto-Detect Source]
  
  Otomatis retarget animasi Explosive LLC ke skeleton Mixamo/Kevin Iglesias.
  Script ini mendeteksi otomatis apakah sumber animasi berupa:
    - Hierarki Empty  → konversi ke Armature dulu, lalu retarget
    - Armature langsung → langsung retarget (lebih cepat!)
  
  Dikonfigurasi berdasarkan scene Blender yang terbuka.
=============================================================================
  CARA PAKAI (Blender sudah terbuka dengan FBX sudah diimport):
  1. Buka tab "Scripting" di Blender
  2. Klik "New", paste seluruh isi script ini
  3. Tekan ▶ Run Script
  4. Buka Window → Toggle System Console untuk melihat log
=============================================================================
"""

import bpy
import mathutils
import os

# =============================================================================
# KONFIGURASI — Disesuaikan dengan scene Blender yang terbuka
# =============================================================================
CONFIG = {
    # Nama Armature TARGET (karakter Mixamo/Kevin Iglesias/Synty)
    # Dari Outliner: "Rig" (armature dengan 56 bone)
    "MIXAMO_ARMATURE_NAME": "Rig",

    # Nama root object Explosive LLC
    # Dari Outliner: "Motion" (root yang berisi B_Pelvis)
    "EXPLOSIVE_ROOT_NAME": "Motion",

    # Jika B_Pelvis di Outliner adalah Armature (bukan Empty),
    # isi nama armature Explosive langsung di sini.
    # Kosongkan ("") untuk deteksi otomatis.
    "EXPLOSIVE_ARMATURE_OVERRIDE": "B_Pelvis",

    # Nama action animasi Explosive LLC
    # Cek di NLA Editor / Action Editor. Biasanya "Take 001".
    "EXPLOSIVE_ACTION_NAME": "Take 001",

    # Path output FBX hasil retarget
    "OUTPUT_FBX_PATH": "C:/Users/User/Desktop/Explosive_Retargeted.fbx",

    # Nama action hasil retarget (muncul di Godot)
    "OUTPUT_ACTION_NAME": "Explosive_Retargeted_Idle",

    # Frame rate
    "FPS": 30,
}

# =============================================================================
# PETA TULANG: Explosive LLC → Mixamo/Kevin Iglesias
# KEY   = nama bone di sumber Explosive LLC
# VALUE = nama bone di Armature Mixamo target ("Rig")
# =============================================================================
BONE_MAP = {
    # Core / Spine
    "B_Pelvis":     "Hips",
    "B_Spine":      "Spine",
    "B_Spine1":     "Chest",
    "B_Spine2":     "UpperChest",
    "B_Neck":       "Neck",
    "B_Head":       "Head",

    # Lengan Kiri
    "B_L_Clavicle": "LeftShoulder",
    "B_L_UpperArm": "LeftUpperArm",
    "B_L_Forearm":  "LeftLowerArm",
    "B_L_Hand":     "LeftHand",

    # Lengan Kanan
    "B_R_Clavicle": "RightShoulder",
    "B_R_UpperArm": "RightUpperArm",
    "B_R_Forearm":  "RightLowerArm",
    "B_R_Hand":     "RightHand",

    # Kaki Kiri
    "B_L_Thigh":    "LeftUpperLeg",
    "B_L_Calf":     "LeftLowerLeg",
    "B_L_Foot":     "LeftFoot",
    "B_L_Toe0":     "LeftToes",

    # Kaki Kanan
    "B_R_Thigh":    "RightUpperLeg",
    "B_R_Calf":     "RightLowerLeg",
    "B_R_Foot":     "RightFoot",
    "B_R_Toe0":     "RightToes",

    # Jari Kiri
    "B_L_Finger0":  "LeftThumbMetacarpal",
    "B_L_Finger01": "LeftThumbProximal",
    "B_L_Finger02": "LeftThumbDistal",
    "B_L_Finger1":  "LeftIndexProximal",
    "B_L_Finger11": "LeftIndexIntermediate",
    "B_L_Finger12": "LeftIndexDistal",
    "B_L_Finger2":  "LeftMiddleProximal",
    "B_L_Finger21": "LeftMiddleIntermediate",
    "B_L_Finger22": "LeftMiddleDistal",
    "B_L_Finger3":  "LeftRingProximal",
    "B_L_Finger31": "LeftRingIntermediate",
    "B_L_Finger32": "LeftRingDistal",
    "B_L_Finger4":  "LeftLittleProximal",
    "B_L_Finger41": "LeftLittleIntermediate",
    "B_L_Finger42": "LeftLittleDistal",

    # Jari Kanan
    "B_R_Finger0":  "RightThumbMetacarpal",
    "B_R_Finger01": "RightThumbProximal",
    "B_R_Finger02": "RightThumbDistal",
    "B_R_Finger1":  "RightIndexProximal",
    "B_R_Finger11": "RightIndexIntermediate",
    "B_R_Finger12": "RightIndexDistal",
    "B_R_Finger2":  "RightMiddleProximal",
    "B_R_Finger21": "RightMiddleIntermediate",
    "B_R_Finger22": "RightMiddleDistal",
    "B_R_Finger3":  "RightRingProximal",
    "B_R_Finger31": "RightRingIntermediate",
    "B_R_Finger32": "RightRingDistal",
    "B_R_Finger4":  "RightLittleProximal",
    "B_R_Finger41": "RightLittleIntermediate",
    "B_R_Finger42": "RightLittleDistal",
}


# =============================================================================
# KODE UTAMA
# =============================================================================

def log(msg):
    print(f"[Retarget] {msg}")


def print_scene_overview():
    log("--- RINGKASAN SCENE ---")
    for obj in bpy.data.objects:
        if obj.parent is None:
            log(f"  ROOT [{obj.type}] '{obj.name}'")
            for child in obj.children:
                log(f"    CHILD [{child.type}] '{child.name}'")
    log("  Actions tersedia:")
    for action in bpy.data.actions:
        log(f"    [ACTION] '{action.name}' frame {action.frame_range[0]:.0f}→{action.frame_range[1]:.0f}")
    log("-----------------------")


def find_source_armature():
    """
    Cari armature sumber Explosive LLC secara otomatis.
    Prioritas:
    1. EXPLOSIVE_ARMATURE_OVERRIDE jika diisi dan ditemukan sebagai Armature
    2. Cari Armature di dalam hierarki EXPLOSIVE_ROOT
    3. Gunakan root jika root itu sendiri adalah Armature
    """
    # --- Opsi 1: Override langsung ---
    override = CONFIG.get("EXPLOSIVE_ARMATURE_OVERRIDE", "")
    if override:
        obj = bpy.data.objects.get(override)
        if obj and obj.type == 'ARMATURE':
            log(f"  [AUTO-DETECT] Sumber = Armature langsung: '{obj.name}'")
            return obj, "ARMATURE"
        else:
            log(f"  [WARN] Override '{override}' tidak ditemukan atau bukan Armature.")

    # --- Opsi 2: Cari di dalam hierarki root ---
    root_name = CONFIG["EXPLOSIVE_ROOT_NAME"]
    root_obj = bpy.data.objects.get(root_name)
    if root_obj:
        # Cek root sendiri
        if root_obj.type == 'ARMATURE':
            log(f"  [AUTO-DETECT] Root sendiri adalah Armature: '{root_obj.name}'")
            return root_obj, "ARMATURE"
        # Cek children
        for child in root_obj.children:
            if child.type == 'ARMATURE':
                log(f"  [AUTO-DETECT] Ditemukan Armature di child root: '{child.name}'")
                return child, "ARMATURE"
        # Semua child adalah Empty
        log(f"  [AUTO-DETECT] Semua child adalah Empty → gunakan hierarki Empty.")
        return root_obj, "EMPTY_HIERARCHY"

    log(f"  [ERROR] Root Explosive '{root_name}' tidak ditemukan!")
    return None, None


def get_frame_range(source_arm):
    """Tentukan frame range dari action yang melekat atau action global."""
    if source_arm.animation_data and source_arm.animation_data.action:
        fs, fe = source_arm.animation_data.action.frame_range
        return int(fs), int(fe)
    action_name = CONFIG["EXPLOSIVE_ACTION_NAME"]
    if action_name in bpy.data.actions:
        fs, fe = bpy.data.actions[action_name].frame_range
        return int(fs), int(fe)
    return bpy.context.scene.frame_start, bpy.context.scene.frame_end


# ---------------------------------------------------------------------------
# Pipeline A: Sumber sudah berupa Armature (jalur cepat!)
# ---------------------------------------------------------------------------
def pipeline_armature_source(source_arm, target_arm, frame_start, frame_end):
    """
    Retarget langsung dari Armature sumber → Armature target.
    Tidak perlu konversi Empty → Armature.
    """
    log("=== PIPELINE A: Direct Armature → Armature Retarget ===")

    # Pastikan action aktif pada source
    if not (source_arm.animation_data and source_arm.animation_data.action):
        action_name = CONFIG["EXPLOSIVE_ACTION_NAME"]
        if action_name in bpy.data.actions:
            source_arm.animation_data_create()
            source_arm.animation_data.action = bpy.data.actions[action_name]
            log(f"  Action '{action_name}' di-assign ke source armature.")
        else:
            log(f"  [ERROR] Action '{action_name}' tidak ditemukan!")
            log(f"  Tersedia: {[a.name for a in bpy.data.actions]}")
            return False

    # Tambah constraint ke setiap bone target
    bpy.context.view_layer.objects.active = target_arm
    bpy.ops.object.mode_set(mode='POSE')

    mapped = 0
    skipped = []
    for src_bone, tgt_bone in BONE_MAP.items():
        if tgt_bone not in target_arm.pose.bones:
            skipped.append(f"target:'{tgt_bone}'")
            continue
        if src_bone not in source_arm.pose.bones:
            skipped.append(f"source:'{src_bone}'")
            continue

        pb = target_arm.pose.bones[tgt_bone]

        # Copy Rotation
        c = pb.constraints.new('COPY_ROTATION')
        c.name = f"_rt_{src_bone}"
        c.target = source_arm
        c.subtarget = src_bone
        c.target_space = 'LOCAL'
        c.owner_space = 'LOCAL'
        c.mix_mode = 'REPLACE'

        # Copy Location (hanya root/Hips untuk root motion)
        if tgt_bone == "Hips":
            cl = pb.constraints.new('COPY_LOCATION')
            cl.name = f"_rt_loc_{src_bone}"
            cl.target = source_arm
            cl.subtarget = src_bone
            cl.target_space = 'WORLD'
            cl.owner_space = 'WORLD'

        mapped += 1

    bpy.ops.object.mode_set(mode='OBJECT')
    log(f"  Constraint dipasang: {mapped} bone. Dilewati: {len(skipped)}")
    if skipped:
        log(f"  Detail skip: {skipped}")

    return True


# ---------------------------------------------------------------------------
# Pipeline B: Sumber berupa hierarki Empty (jalur lengkap)
# ---------------------------------------------------------------------------
def get_empty_hierarchy(root_obj):
    result = {}
    def _collect(obj):
        result[obj.name] = obj
        for c in obj.children:
            _collect(c)
    _collect(root_obj)
    return result


def build_armature_from_empties(root_obj, empty_hierarchy):
    log("=== B.1: Konversi Hierarki Empty → Armature ===")
    arm_data = bpy.data.armatures.new("ExplosiveArmData")
    arm_obj = bpy.data.objects.new("ExplosiveArmObj", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='EDIT')

    eb_map = {}

    def _make_bone(obj, parent_eb=None):
        eb = arm_data.edit_bones.new(obj.name)
        eb.head = obj.matrix_world.translation.copy()
        children = list(obj.children)
        if children:
            cp = children[0].matrix_world.translation.copy()
            diff = cp - eb.head
            eb.tail = cp if diff.length > 0.001 else eb.head + mathutils.Vector((0, 0.05, 0))
        elif parent_eb:
            d = (parent_eb.tail - parent_eb.head).normalized()
            eb.tail = eb.head + (d if d.length > 0.001 else mathutils.Vector((0, 1, 0))) * 0.04
        else:
            eb.tail = eb.head + mathutils.Vector((0, 0.05, 0))
        if parent_eb:
            eb.parent = parent_eb
            eb.use_connect = False
        eb_map[obj.name] = eb
        for child in obj.children:
            _make_bone(child, eb)

    _make_bone(root_obj)
    bpy.ops.object.mode_set(mode='OBJECT')
    log(f"  Dibuat {len(eb_map)} bone.")
    return arm_obj


def bake_empty_to_armature(arm_obj, empty_hierarchy, bone_names, fs, fe):
    log(f"=== B.2: Bake Empty Anim → Armature ({fs}→{fe}) ===")
    action = bpy.data.actions.new("ExplosiveSourceBaked")
    arm_obj.animation_data_create()
    arm_obj.animation_data.action = action
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')
    for pb in arm_obj.pose.bones:
        pb.rotation_mode = 'QUATERNION'

    for frame in range(fs, fe + 1):
        bpy.context.scene.frame_set(frame)
        for bname in bone_names:
            if bname not in empty_hierarchy or bname not in arm_obj.pose.bones:
                continue
            emp = empty_hierarchy[bname]
            pb = arm_obj.pose.bones[bname]
            wm = emp.matrix_world.copy()
            if pb.parent:
                pm = arm_obj.matrix_world @ pb.parent.matrix
                lm = pm.inverted_safe() @ wm
            else:
                lm = arm_obj.matrix_world.inverted_safe() @ wm
            loc, rot, _ = lm.decompose()
            pb.location = loc
            pb.rotation_quaternion = rot
            pb.keyframe_insert("location", frame=frame)
            pb.keyframe_insert("rotation_quaternion", frame=frame)
        if frame % 20 == 0:
            log(f"  Frame {frame}/{fe}")

    bpy.ops.object.mode_set(mode='OBJECT')
    log("  Bake selesai.")
    return arm_obj


def pipeline_empty_source(root_obj, target_arm, frame_start, frame_end):
    log("=== PIPELINE B: Empty Hierarchy → Armature Retarget ===")
    empty_h = get_empty_hierarchy(root_obj)
    src_arm = build_armature_from_empties(root_obj, empty_h)
    bake_empty_to_armature(src_arm, empty_h, list(empty_h.keys()), frame_start, frame_end)
    # Setelah bake, lanjut ke pipeline A (constraint-based)
    return src_arm


# ---------------------------------------------------------------------------
# Visual Bake & Export (dipakai oleh kedua pipeline)
# ---------------------------------------------------------------------------
def do_visual_bake(target_arm, frame_start, frame_end):
    log(f"=== VISUAL BAKE ke Mixamo Armature ({frame_start}→{frame_end}) ===")
    output_action = bpy.data.actions.new(CONFIG["OUTPUT_ACTION_NAME"])
    target_arm.animation_data_create()
    target_arm.animation_data.action = output_action

    bpy.context.view_layer.objects.active = target_arm
    target_arm.select_set(True)
    bpy.ops.object.mode_set(mode='POSE')
    bpy.ops.pose.select_all(action='SELECT')

    bpy.ops.nla.bake(
        frame_start=frame_start,
        frame_end=frame_end,
        only_selected=True,
        visual_keying=True,
        clear_constraints=True,
        use_current_action=True,
        bake_types={'POSE'},
    )
    bpy.ops.object.mode_set(mode='OBJECT')
    log(f"  Bake selesai. Action: '{CONFIG['OUTPUT_ACTION_NAME']}'")
    return output_action


def export_fbx(target_arm, output_path):
    log(f"=== EXPORT FBX → {output_path} ===")
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    target_arm.select_set(True)
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            for mod in obj.modifiers:
                if mod.type == 'ARMATURE' and mod.object == target_arm:
                    obj.select_set(True)
    bpy.context.view_layer.objects.active = target_arm

    bpy.ops.export_scene.fbx(
        filepath=output_path,
        use_selection=True,
        object_types={'ARMATURE', 'MESH'},
        bake_anim=True,
        bake_anim_use_all_actions=False,
        bake_anim_use_nla_strips=False,
        bake_anim_step=1,
        bake_anim_simplify_factor=0.0,
        add_leaf_bones=False,
        primary_bone_axis='Y',
        secondary_bone_axis='X',
        axis_forward='-Z',
        axis_up='Y',
        mesh_smooth_type='OFF',
    )
    log(f"  SUKSES! FBX → {output_path}")


# =============================================================================
# MAIN
# =============================================================================
def main():
    log("=" * 60)
    log("  AUTO-RETARGET v2: Explosive LLC → Mixamo")
    log("=" * 60)
    print_scene_overview()

    # Cari Mixamo armature target
    target_arm = bpy.data.objects.get(CONFIG["MIXAMO_ARMATURE_NAME"])
    if not target_arm or target_arm.type != 'ARMATURE':
        log(f"[ERROR] Armature target '{CONFIG['MIXAMO_ARMATURE_NAME']}' tidak ditemukan!")
        log("  Cek Outliner dan update CONFIG['MIXAMO_ARMATURE_NAME']")
        return

    log(f"  Target Mixamo : '{target_arm.name}' ({len(target_arm.data.bones)} bones)")

    # Deteksi otomatis sumber Explosive LLC
    source_obj, source_type = find_source_armature()
    if not source_obj:
        return

    # Tentukan frame range
    if source_type == "ARMATURE":
        fs, fe = get_frame_range(source_obj)
    else:
        # Hierarki Empty: cek semua animasi
        empty_h = get_empty_hierarchy(source_obj)
        fs = min(
            (obj.animation_data.action.frame_range[0]
             for obj in empty_h.values()
             if obj.animation_data and obj.animation_data.action),
            default=bpy.context.scene.frame_start
        )
        fe = max(
            (obj.animation_data.action.frame_range[1]
             for obj in empty_h.values()
             if obj.animation_data and obj.animation_data.action),
            default=bpy.context.scene.frame_end
        )
        fs, fe = int(fs), int(fe)

    log(f"  Frame range   : {fs} → {fe}")
    bpy.context.scene.render.fps = CONFIG["FPS"]
    bpy.context.scene.frame_start = fs
    bpy.context.scene.frame_end = fe

    # Jalankan pipeline yang sesuai
    if source_type == "ARMATURE":
        ok = pipeline_armature_source(source_obj, target_arm, fs, fe)
        if not ok:
            return
    else:
        source_obj = pipeline_empty_source(source_obj, target_arm, fs, fe)
        ok = pipeline_armature_source(source_obj, target_arm, fs, fe)
        if not ok:
            return

    # Visual Bake ke action output
    do_visual_bake(target_arm, fs, fe)

    # Export FBX
    export_fbx(target_arm, CONFIG["OUTPUT_FBX_PATH"])

    log("")
    log("=" * 60)
    log("  SELESAI!")
    log(f"  Output : {CONFIG['OUTPUT_FBX_PATH']}")
    log("  Selanjutnya: Import FBX ini ke Godot 4.")
    log("=" * 60)


main()
