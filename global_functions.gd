extends Node3D
class_name GlobalFunctions
#var parent: Node3D = null

static func grab_rigid_parent(child): # Looks three layers up for first RigidBody3D. If none found, report and kill self.
	# Probably a way smarter way of doing this.
	# HOLY SHIT THIS IS GETTING DUMB
	# MAYBE THE PARENT SHOULD DO THIS???
	var parent: Node3D = null
	if child.get_parent() is RigidBody3D:
		parent = child.get_parent()
		return parent
	if child.get_parent().name == "root":
		print("NODE IS ROOT")
		print(child)
		child.queue_free()
		return
	if child.get_parent().get_parent() is RigidBody3D:
		parent = child.get_parent().get_parent()
		return parent
	if child.get_parent().get_parent().get_parent() is RigidBody3D:
		parent = child.get_parent().get_parent().get_parent()
		return parent
	if child.get_parent().get_parent().get_parent().get_parent() is RigidBody3D:
		parent = child.get_parent().get_parent().get_parent().get_parent()
		return parent
	if child.get_parent().get_parent().get_parent().get_parent().get_parent() is RigidBody3D:
		parent = child.get_parent().get_parent().get_parent().get_parent().get_parent()
		return parent
	if child.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent() is RigidBody3D:
		parent = child.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
		return parent
	print("NODE FOUND NO PARENT APPLICABLE")
	print(child)
	child.queue_free()

static func thousands_sep(number, prefix=''):
	number = int(number)
	var neg = false
	if number < 0:
		number = -number
		neg = true
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	if neg: res = '-'+prefix+res
	else: res = prefix+res
	return res
