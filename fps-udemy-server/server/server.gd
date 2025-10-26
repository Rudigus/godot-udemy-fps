extends Node

const PORT := 7777
const MAX_CLIENTS := 64
const MAX_LOBBIES := 1
const MAX_PLAYERS_PER_LOBBY := 2

var peer := ENetMultiplayerPeer.new()

var lobbies: Array[Lobby] = []
var idle_clients: Array[int] = []

func _ready() -> void:
	var error := peer.create_server(PORT, MAX_CLIENTS)
	if error != OK: 
		print("Failed to start server.")
		return
	print("Server started.")
		
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	print("Client %d connected to server." % id)
	idle_clients.append(id)

func _on_peer_disconnected(id: int) -> void:
	print("Client %d disconnected from server." % id)
	var maybe_lobby := get_lobby_from_client_id(id)
	if maybe_lobby:
		maybe_lobby.remove_client(id)
		if maybe_lobby.clients.is_empty():
			lobbies.erase(maybe_lobby)
			maybe_lobby.queue_free()
	idle_clients.erase(id)

func get_lobby_from_client_id(id: int) -> Lobby:
	for lobby in lobbies:
		if lobby.clients.has(id):
			return lobby
	return null

@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby() -> void:
	var client_id := multiplayer.get_remote_sender_id()
	var maybe_lobby := get_non_full_lobby()
	if maybe_lobby:
		maybe_lobby.add_client(client_id)
		idle_clients.erase(client_id)
		print("Client %d connected to lobby %s." % [client_id, maybe_lobby.name])
	else:
		print("No available lobby for client %d." % client_id)
		# TODO logic when lobbies are full and client tries to connect to one 

func get_non_full_lobby() -> Lobby:
	for lobby in lobbies:
		if lobby.clients.size() < MAX_PLAYERS_PER_LOBBY:
			return lobby
	if lobbies.size() < MAX_LOBBIES:
		var new_lobby := Lobby.new()
		lobbies.append(new_lobby)
		new_lobby.name = str(new_lobby.get_instance_id())
		add_child(new_lobby)
		return new_lobby
	print("Lobbies full.")
	return null
