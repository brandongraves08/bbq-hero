extends Node
## Global event bus for decoupled cross-system communication.
## Systems emit and listen through named events rather than importing each other.
##
## Usage:
##   EventBus.on("meat_cooked", _on_meat_cooked)
##   EventBus.emit("meat_cooked", {"meat": "brisket", "score": 92})

extends Node

var _listeners: Dictionary = {}

func on(event_name: String, callback: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	_listeners[event_name].append(callback)

func off(event_name: String, callback: Callable) -> void:
	if not _listeners.has(event_name):
		return
	_listeners[event_name].erase(callback)
	if _listeners[event_name].is_empty():
		_listeners.erase(event_name)

func emit(event_name: String, data = null) -> void:
	if not _listeners.has(event_name):
		return
	# Copy to avoid mutation during iteration
	for callback in _listeners[event_name].duplicate():
		if data != null:
			callback.call(data)
		else:
			callback.call()

func has_listeners(event_name: String) -> bool:
	return _listeners.has(event_name) and not _listeners[event_name].is_empty()

func clear_all() -> void:
	_listeners.clear()
