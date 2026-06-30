import os
import glob

# Path to the folder containing customization FBX files
target_dir = r"E:\Ananto\Emulatoid\Tales of The Dark Time 3D\Assets\Models\CharacterCustomization\Meshes\Species\Humans"

# The _subresources string to inject
subresources_str = """_subresources={
"nodes": {
"PATH:Skeleton3D": {
"retarget/bone_map": Object(BoneMap,"resource_local_to_scene":false,"resource_name":"","profile":Object(SkeletonProfileHumanoid,"resource_local_to_scene":false,"resource_name":"","root_bone":&"Root","scale_base_bone":&"Hips","group_size":4,"bone_size":56,"script":null)
,"bonemap":null,"bone_map/Root":&"root","bone_map/Hips":&"pelvis","bone_map/Spine":&"spine_01","bone_map/Chest":&"spine_02","bone_map/UpperChest":&"neck_01","bone_map/Neck":&"neck_01","bone_map/Head":&"head","bone_map/LeftEye":&"eye_l","bone_map/RightEye":&"eye_r","bone_map/Jaw":&"jaw","bone_map/LeftShoulder":&"clavicle_l","bone_map/LeftUpperArm":&"upperarm_l","bone_map/LeftLowerArm":&"lowerarm_l","bone_map/LeftHand":&"hand_l","bone_map/LeftThumbMetacarpal":&"","bone_map/LeftThumbProximal":&"","bone_map/LeftThumbDistal":&"","bone_map/LeftIndexProximal":&"","bone_map/LeftIndexIntermediate":&"","bone_map/LeftIndexDistal":&"","bone_map/LeftMiddleProximal":&"","bone_map/LeftMiddleIntermediate":&"","bone_map/LeftMiddleDistal":&"","bone_map/LeftRingProximal":&"","bone_map/LeftRingIntermediate":&"","bone_map/LeftRingDistal":&"","bone_map/LeftLittleProximal":&"","bone_map/LeftLittleIntermediate":&"","bone_map/LeftLittleDistal":&"","bone_map/RightShoulder":&"clavicle_r","bone_map/RightUpperArm":&"upperarm_r","bone_map/RightLowerArm":&"lowerarm_r","bone_map/RightHand":&"hand_r","bone_map/RightThumbMetacarpal":&"","bone_map/RightThumbProximal":&"","bone_map/RightThumbDistal":&"","bone_map/RightIndexProximal":&"","bone_map/RightIndexIntermediate":&"","bone_map/RightIndexDistal":&"","bone_map/RightMiddleProximal":&"","bone_map/RightMiddleIntermediate":&"","bone_map/RightMiddleDistal":&"","bone_map/RightRingProximal":&"","bone_map/RightRingIntermediate":&"","bone_map/RightRingDistal":&"","bone_map/RightLittleProximal":&"","bone_map/RightLittleIntermediate":&"","bone_map/RightLittleDistal":&"","bone_map/LeftUpperLeg":&"thigh_l","bone_map/LeftLowerLeg":&"calf_l","bone_map/LeftFoot":&"foot_l","bone_map/LeftToes":&"","bone_map/RightUpperLeg":&"thigh_r","bone_map/RightLowerLeg":&"calf_r","bone_map/RightFoot":&"foot_r","bone_map/RightToes":&"","script":null)

}
}
}
"""

def patch_import_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # If already fully patched with bone_map
    if "retarget/bone_map" in content:
        return False

    if "_subresources={}" in content:
        content = content.replace("_subresources={}", subresources_str)
    else:
        # If it has some other subresources, this is harder, but we know these are empty
        content += "\n" + subresources_str
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

count = 0
for filepath in glob.glob(os.path.join(target_dir, "*.fbx.import")):
    if patch_import_file(filepath):
        count += 1

print(f"Patched {count} .import files successfully!")
