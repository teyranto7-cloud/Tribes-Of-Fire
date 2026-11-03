extends Node3D
## Nine articulated joints; surfaces consolidated per attachment and material.
const Shapes = preload("res://World/Shapes.gd")
const ACTIONS := ["gather", "mine", "build", "eat", "craft", "fish", "cook", "tame"]
var skeleton: Skeleton3D
var controls: Array[Node3D] = []
var attachments: Array[BoneAttachment3D] = []
var action_kind: String = ""
var action_left: float = 0.0
var action_duration: float = 1.0
var _phase: float = 0.0

func setup(player) -> void:
	skeleton = Skeleton3D.new()
	add_child(skeleton)
	controls.assign([player.torso, player.head, player.left_leg, player.left_knee, player.right_leg, player.right_knee, player.left_arm, player.axe_arm, player.axe])
	for i in range(controls.size()):
		var node := controls[i]
		skeleton.add_bone("joint_%d" % i)
		var parent := controls.find(node.get_parent())
		if parent >= 0: skeleton.set_bone_parent(i, parent)
		skeleton.set_bone_rest(i, node.transform)
		skeleton.set_bone_pose_position(i, node.position)
		var attachment := BoneAttachment3D.new()
		attachments.append(attachment)
		attachment.bone_name = "joint_%d" % i
		skeleton.add_child(attachment)
		for child in node.get_children():
			if not child in controls: child.reparent(attachment, false)
		Shapes.consolidate(attachment)

func start_action(kind: String, seconds: float) -> void:
	if kind not in ACTIONS or not is_finite(seconds) or seconds <= 0:
		action_kind = ""
		action_left = 0
		return
	action_kind = kind
	action_duration = clampf(seconds, 0.15, 30.0)
	action_left = action_duration

func set_action_state(kind: String, remaining: float, duration: float) -> void:
	if kind not in ACTIONS or remaining <= 0:
		action_left = 0
		action_kind = ""
		return
	action_kind = kind
	action_duration = maxf(0.15, duration)
	action_left = clampf(remaining, 0, action_duration)

func _process(delta: float) -> void:
	action_left = maxf(0, action_left - delta)
	_phase += delta
	var action_weight := sin(clampf(action_left / maxf(action_duration,0.01),0,1)*PI)
	for i in range(controls.size()):
		if not is_instance_valid(controls[i]): continue
		var rotation: Quaternion = controls[i].quaternion
		var bend := 0.0
		if action_left > 0:
			match action_kind:
				"eat", "tame":
					if i == 7: bend = -1.25*action_weight
					elif i == 1: bend = 0.12*action_weight
				"gather", "fish":
					if i == 0: bend = 0.32*action_weight
					elif i in [6,7]: bend = -0.65*action_weight
				"mine", "build", "craft", "cook":
					if i == 7: bend = -sin(_phase*10)*0.60*action_weight-0.40*action_weight
					elif i == 0: bend = 0.10*action_weight
		rotation *= Quaternion(Vector3.RIGHT,bend)
		skeleton.set_bone_pose_position(i,controls[i].position)
		skeleton.set_bone_pose_rotation(i,rotation)
		skeleton.set_bone_pose_scale(i,controls[i].scale)
