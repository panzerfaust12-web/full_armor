extends RigidBody3D
var debug: bool
var component

func _ready():
	_generate_collisions()
	component = $MountAnything.get_child(0)
	if component != null:
		mass = component.weight
	if get_parent() != null:
		if get_parent().name == "Solo_Component_Scene": debug = true
	
func _generate_collisions():
	var transforms: Array
	#Remove Any Leftover Duplicated Collisions
	var colremove: Array = find_children("DuplicatedCollision*","CollisionShape3D")
	for i in colremove:
		queue_free()
	#Generate Some Meshes if no Collisions
	var collisions: Array = find_children("*Collision*","CollisionShape3D")
	var meshes: Array = find_children("*Mesh*","MeshInstance3D")
	if collisions.is_empty():
		for i in meshes:
			i.create_convex_collision(1,1)
			transforms.append(i.transform)
	#Copy Dem Bitches
	collisions = find_children("*Collision*","CollisionShape3D")
	var index = 0
	for cm in collisions:
		var cmcopy = cm.duplicate()
		cmcopy.name = "DuplicatedCollision" + str(index)
		if not transforms.is_empty(): cmcopy.transform = transforms[index]
		#if cm.get_parent().get_parent().name.contains("Mount"):
			#cmcopy.position += cm.get_parent().get_parent().position
		add_child(cmcopy)
		index += 1
	#DeleteDaStaticBodies
	var staticbodies: Array = find_children("*","StaticBody3D")
	for i in staticbodies:
		i.queue_free()

func _process(delta: float) -> void:
	if not debug: return
	var target = get_parent().get_node("ConeTwistJoint3D").position
	DebugDraw3D.draw_line(global_position, target, Color.DARK_SLATE_BLUE)
	DebugDraw3D.draw_arrow_ray(global_position,global_basis.x,linear_velocity.x,Color.RED,0.05)
	DebugDraw3D.draw_arrow_ray(global_position,global_basis.y,linear_velocity.y,Color.GREEN,0.05)
	DebugDraw3D.draw_arrow_ray(global_position,global_basis.z,linear_velocity.z,Color.BLUE,0.05)
	_get_vars()

func _get_vars():
	var values: Array
	values.clear()
	if component == null:
		return
	else:
		for propertyInfo in component.get_script().get_script_property_list():
			var propertyName: String = propertyInfo.name
			var propertyValue = component.get(propertyName)
			values.append(' %s = %s' % [ propertyName, propertyValue ])
		var values_text = array_to_string(values)
		get_parent().find_child("RichTextLabel").text = values_text


func array_to_string(arr: Array) -> String:
	var s = ""
	for i in arr:
		s += String(i) + "\n"
	return s
