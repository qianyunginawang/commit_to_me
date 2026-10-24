class_name TestCase
extends RefCounted
## Base class for tests. See tests/run_tests.gd.

var tree: SceneTree
var failures: PackedStringArray = []
## Extra text printed after PASS (e.g. " (skipped: no python)").
var note: String = ""
var _nodes_to_free: Array[Node] = []


func check(condition: bool, message: String = "check failed") -> void:
	if not condition:
		failures.append(message)


func check_eq(actual, expected, message: String = "") -> void:
	if typeof(actual) != typeof(expected) and not (_is_number(actual) and _is_number(expected)):
		failures.append("%s expected %s (%s) but got %s (%s)" % [message, expected, type_string(typeof(expected)), actual, type_string(typeof(actual))])
	elif actual != expected:
		failures.append("%s expected %s but got %s" % [message, var_to_str(expected), var_to_str(actual)])


func skip(reason: String) -> void:
	note = "  (skipped: %s)" % reason


## Adds a node to the scene tree for the test; it's freed afterwards.
func add_node(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes_to_free.append(node)
	return node


func cleanup() -> void:
	for n in _nodes_to_free:
		if is_instance_valid(n):
			n.free()


static func _is_number(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
