extends Node


class LoadRequest:
	var path:String
	var type_hint:String
	var completion_callback:FuncRef
	var progress_callback:FuncRef
	func _init(set_path:String, set_type_hint:String,
			set_completion_callback:FuncRef, set_progress_callback:FuncRef = FuncRef.new()):
		path = set_path
		type_hint = set_type_hint
		completion_callback = set_completion_callback
		progress_callback = set_progress_callback


# Changing this during runtime could break request_queue
# (single-thread mode doesn't use the mutexes,
# and thread(s) will still be running).
# Could add custom setter if this is ever needed
var use_threads := true

const thread_count = 1

#These are only used in single-thread mode
var current_request:LoadRequest = null
var loader:ResourceInteractiveLoader

var request_queue:Array
onready var request_queue_mutex:Mutex = Mutex.new()

var threads:Array
onready var semaphore:Semaphore = Semaphore.new()

var stop_threads:bool setget _set_stop_threads, _get_stop_threads
onready var stop_mutex:Mutex = Mutex.new()


func _ready() -> void:
	set_process(false)
	if OS.can_use_threads():
		for i in thread_count:
			threads.append( Thread.new() )
			threads[i].start(self, "_loader_thread")
	else:
		use_threads = false


func load(request:LoadRequest, high_priority:bool = false) -> void:
	if ResourceLoader.has_cached(request.path):
		_callback_complete(request, ResourceLoader.load(request.path))
		return
	
	if use_threads:
		request_queue_mutex.lock()
		if high_priority:
			request_queue.push_front(request)
		else:
			request_queue.append(request)
		request_queue_mutex.unlock()
		semaphore.post()
	else:
		if high_priority:
			request_queue.push_front(request)
		else:
			request_queue.append(request)
		set_process(true)


var target_frame_time:int = 1000/60#TODO: Move these two to the top of the file<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
var last_ticks:float = 0#Needed because delta doesn't seem to work right sometimes (in 3.2.3)
var load_error:int
func _process(_delta) -> void:#Current limitation: this (single-thread mode) can load at most 1 resource per _process() call
	if not use_threads:
		if not current_request:
			if request_queue.size() > 0:
				current_request = request_queue.pop_front()
				loader = ResourceLoader.load_interactive(
					current_request.path, current_request.type_hint)
				if loader == null:
					_callback_complete(current_request, ResourceLoader.load(current_request.path))
					current_request = null
			else:
				set_process(false)
		
		if current_request:
			load_error = loader.poll()
			while OS.get_ticks_msec() - last_ticks < target_frame_time - 1:
				if load_error == OK:
					load_error = loader.poll()
				else:
					if load_error == ERR_FILE_EOF:
						_callback_complete(current_request, loader.get_resource())
						current_request = null
					else:
						push_error("Loading failed with error %i"%load_error)
					break
			if load_error == OK:
				_callback_progress(current_request,
					100.0 * loader.get_stage() / loader.get_stage_count())
	
	last_ticks = OS.get_ticks_msec()


func _loader_thread(data) -> void:
	var request:LoadRequest
	var loader:ResourceInteractiveLoader
	var err
	while true:
		semaphore.wait()
		
		stop_mutex.lock()
		var stop_now = stop_threads
		stop_mutex.unlock()
		if stop_now:
			break
		
		request_queue_mutex.lock()
		request = request_queue.pop_front()
		request_queue_mutex.unlock()
		loader = ResourceLoader.load_interactive(request.path, request.type_hint)
		if loader == null:
			call_deferred( "_callback_complete", request, ResourceLoader.load(request.path) )
			continue
		err = loader.poll()
		while true:
			if err == OK:
				_callback_progress(request, 100.0 * loader.get_stage() / loader.get_stage_count())
				err = loader.poll()
			else:
				if err == ERR_FILE_EOF:
					_callback_complete( request, loader.get_resource())
				else:
					call_deferred("push_error", err)
				break

func _callback_progress(request:LoadRequest, percent:float) -> void:
	if request.progress_callback.is_valid():
		request.progress_callback.call_func(percent)

func _callback_complete(request:LoadRequest, resource) -> void:
	_callback_progress( request, 100.0)
	if request.completion_callback.is_valid():
		request.completion_callback.call_func(resource)


func _exit_tree() -> void:
	_set_stop_threads(true)


func _set_stop_threads(value) -> void:
	if value==true and stop_threads==false:
		stop_mutex.lock()
		stop_threads = true
		stop_mutex.unlock()
		for i in thread_count:
			semaphore.post()
		for thread in threads:
			thread.wait_to_finish()

func _get_stop_threads() -> bool:
	stop_mutex.lock()
	var value = stop_threads
	stop_mutex.unlock()
	return value
