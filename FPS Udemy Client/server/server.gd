extends Node

const PORT := 7777
const ADDRESS := "127.0.0.1"

var peer := ENetMultiplayerPeer.new()

func _ready() -> void:
	var error := peer.create_client(ADDRESS, PORT)
	if error != OK:
		print("Failed to connect to server.")
		return
	
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connected_to_server() -> void:
	print("Connected to server.")

func _on_connection_failed() -> void:
	print("Failed to connect to server.")

func try_connect_client_to_lobby() -> void:
	c_try_connect_client_to_lobby.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby() -> void:
	pass
