# Multiplayer backend note

The Godot Web client is prepared for a future 12-player WebSocket room server, but GitHub Pages only hosts static files and cannot host a WebSocket server.

For a public 12-player build, deploy a Godot/native WebSocket relay on a TLS-enabled host (WSS) and point the client network URL to it. The static game remains fully playable offline/single-player without that backend.
