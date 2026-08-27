# PLAKORO Online Server

Authoritative room and battle service for PLAKORO Online VS. It keeps private
Loadouts until both players are ready, chooses the first player, rolls all
Enerkoro and Charakoro results, resolves common Move effects and weakness, and
broadcasts the same turn result to both clients. It also resolves explicit
forfeits and opponent disconnects.

## Local development

```bash
pnpm install
pnpm start
```

Health check: `http://localhost:10000/health`  
WebSocket endpoint: `ws://localhost:10000/ws`

## Render

Create a Render Web Service with:

- Root Directory: `online-server`
- Instance Type: `Free`
- Build Command: `pnpm install --frozen-lockfile`
- Start Command: `pnpm start`
- Health Check Path: `/health`

Render supplies `PORT`. Public clients must use `wss://<service>.onrender.com/ws`.

The repository-root `render.yaml` can create this service as a Render
Blueprint. After the first deployment:

1. Open `https://<service>.onrender.com/health` and confirm `{"ok":true,...}`.
2. Set Godot project setting `online/server_url` to
   `wss://<service>.onrender.com/ws`.
3. Export two clients, create a room on one, join with the six-character code
   on the other, and submit both Loadouts.

## Current scope

Room and match state are currently in memory. A Render restart clears active
rooms. A dropped connection keeps its seat for 30 seconds and the client
automatically resumes the same player id, Loadout, HP, and turn when possible.
After the grace period, an active match is resolved as a disconnect loss.
Waiting rooms expire after 15 minutes of inactivity and finished rooms after
3 minutes, keeping the free Render instance from accumulating stale state.
This in-memory foundation is still not intended for ranked or long-running
matches because a Render restart cannot restore a room.
