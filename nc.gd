extends Node

# Dictionary to store notifications and their handlers
var _table = {}

# Set to track invoking handlers
var _invoking = []

# Singleton pattern
static var instance = null

func _ready():
	# Ensure that there's only one instance of NotificationCenter
	if instance == null:
		instance = self
	else:
		queue_free()

# Add an observer to a notification
func add_observer(handler, notification_name, sender = null):
	if handler == null:
		print("Can't add a null event handler for notification:", notification_name)
		return

	if notification_name == "":
		print("Can't observe an unnamed notification")
		return

	if !_table.has(notification_name):
		_table[notification_name] = {}

	var sub_table = _table[notification_name]
	var key = sender if sender != null else self

	if !sub_table.has(key):
		sub_table[key] = []

	var handler_list = sub_table[key]

	if handler not in handler_list:
		if handler_list in _invoking:
			sub_table[key] = handler_list.duplicate()

		handler_list.append(handler)

# Remove an observer from a notification
func remove_observer(handler, notification_name, sender = null):
	if handler == null:
		print("Can't remove a null event handler for notification:", notification_name)
		return

	if notification_name == "" or !_table.has(notification_name):
		return

	var sub_table = _table[notification_name]
	var key = sender if sender != null else self

	if sub_table.has(key):
		var handler_list = sub_table[key]
		var index = handler_list.find(handler)

		if index != -1:
			if handler_list in _invoking:
				sub_table[key] = handler_list.duplicate()

			handler_list.remove(index)

			if handler_list.size() == 0:
				sub_table.erase(key)

	clean()

# Remove empty entries from the notification table
func clean():
	var keys = _table.keys()

	for notification_name in keys:
		var sender_table = _table[notification_name]
		var sender_keys = sender_table.keys()

		for sender_key in sender_keys:
			var handlers = sender_table[sender_key]

			if handlers.size() == 0:
				sender_table.erase(sender_key)

		if sender_table.size() == 0:
			_table.erase(notification_name)

# Post a notification
func post_notification(notification_name, sender = null, e = null):
	if notification_name == "":
		print("A notification name is required")
		return

	if !_table.has(notification_name):
		return

	var sub_table = _table[notification_name]

	if sender != null and sub_table.has(sender):
		var handlers = sub_table[sender]
		_invoking.append(handlers)

		for handler in handlers:
			if sender.has_method(handler.get_method()):
				sender.call(handler.get_method(),sender, e)

		_invoking.erase(handlers)

	if sub_table.has(self):
		var handlers = sub_table[self]
		_invoking.append(handlers)

		for handler in handlers:
			if sender.has_method(handler.get_method()):
				sender.call(handler.get_method(),e)

		_invoking.erase(handlers)
