class_name ThreadHelper

static func run_thread( callback: Callable, args := []) -> void:
	var thread = Thread.new();
	var result = thread.start(_thread_function.bind(callback, args));
	thread.wait_to_finish();


static func _thread_function(callback: Callable, args: Array):
	var result = callback.callv(args);
	if result is Callable:
		result.call_deferred();
