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

class Callback:
	var callback_func:FuncRef
	var data

var request_queue:Array
onready var request_queue_mutex:Mutex = Mutex.new()

var callback_queue:Array
onready var callback_queue_mutex:Mutex = Mutex.new()

const thread_count = 1

var threads:Array
onready var semaphore:Semaphore = Semaphore.new()

var stop_threads:bool setget _set_stop_threads, _get_stop_threads
onready var stop_mutex:Mutex = Mutex.new()


func _ready():
	for i in thread_count:
		threads.append( Thread.new() )
		threads[i].start(self, "_loader_thread")


func load(request:LoadRequest, high_priority:bool = false):
	print(request.path)
	if ResourceLoader.has_cached(request.path):
		call_deferred( "_callback_complete", request, ResourceLoader.load(request.path) )
		return
	request_queue_mutex.lock()
	if high_priority:
		request_queue.push_front(request)
	else:
		request_queue.append(request)
	request_queue_mutex.unlock()
	semaphore.post()


func _loader_thread(data):
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
			if err == ERR_FILE_EOF:
				call_deferred( "_callback_complete", request, loader.get_resource() )
				break
			elif err == OK:
				call_deferred( "_callback_progress", request, 100.0 * loader.get_stage() / loader.get_stage_count() )
				err = loader.poll()
			else:
				call_deferred("push_error", err)
				break

func _callback_progress(request:LoadRequest, percent:float):
	if request.progress_callback.is_valid():
		request.progress_callback.call_func(percent)

func _callback_complete(request:LoadRequest, resource):
	_callback_progress(request, 100.0)
	if request.completion_callback.is_valid():
		request.completion_callback.call_func(resource)

func _exit_tree():
	_set_stop_threads(true)


#func _set_loader_threads(count):#this is almost certainly totally useless
#	if count == loader_threads:
#		return
#	else:
#		if count < loader_threads:
#			stop_mutex.lock()
#			for i in range(loader_threads, count-1):
#				stop_thread[i] = true
#			stop_mutex.unlock()
#			for i in threads:
#				semaphore.post()#this is stupid and won't always stop all of them.
#			for i in range(count, loader_threads-1):
#				threads[i].wait_to_finish()
#		else:
#			for i in range(count, loader_threads-1):
#				threads.append(Thread.new())
#				threads[i].start(self, "_loader_thread", i)
#		loader_threads = count

func _set_stop_threads(value):
	if value==true and stop_threads==false:
		stop_mutex.lock()
		stop_threads = true
		stop_mutex.unlock()
		for i in thread_count:
			semaphore.post()
		for thread in threads:
			thread.wait_to_finish()

func _get_stop_threads():
	stop_mutex.lock()
	var value = stop_threads
	stop_mutex.unlock()
	return value
