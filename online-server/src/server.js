import { createServer } from "node:http";
import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { WebSocket, WebSocketServer } from "ws";

const PORT = Number.parseInt(process.env.PORT ?? "10000", 10);
const ROOM_CODE_LENGTH = 6;
const MAX_PLAYERS = 2;
const RECONNECT_GRACE_MS = Number.parseInt(process.env.RECONNECT_GRACE_MS ?? "30000", 10);
const WAITING_ROOM_TTL_MS = Number.parseInt(process.env.WAITING_ROOM_TTL_MS ?? "900000", 10);
const FINISHED_ROOM_TTL_MS = Number.parseInt(process.env.FINISHED_ROOM_TTL_MS ?? "180000", 10);
const HEARTBEAT_MS = Number.parseInt(process.env.HEARTBEAT_MS ?? "25000", 10);
const REPOSITORY_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const ORIENTATIONS = ["FACE_DOWN", "FACE_UP", "HEAD_UP", "HEAD_DOWN", "HEAD_LEFT", "HEAD_RIGHT"];
const rooms = new Map();
const clients = new Map();
const randomQueue = [];

const server = createServer((request, response) => {
  if (request.url === "/health") {
    response.writeHead(200, { "content-type": "application/json" });
    response.end(JSON.stringify({ ok: true, rooms: rooms.size, random_queue: randomQueue.length }));
    return;
  }
  response.writeHead(200, { "content-type": "application/json" });
  response.end(JSON.stringify({
    service: "plakoro-online",
    protocol: 3,
    websocket: "/ws"
  }));
});

const websocketServer = new WebSocketServer({ server, path: "/ws" });

websocketServer.on("connection", (socket) => {
  const client = {
    id: randomBytes(8).toString("hex"),
    reconnectToken: randomBytes(24).toString("hex"),
    name: "Player",
    roomCode: null,
    connected: true,
    disconnectTimer: null,
    socket
  };
  socket.isAlive = true;
  clients.set(socket, client);
  sendConnected(client, false);

  socket.on("message", (buffer) => handleMessage(client, buffer));
  socket.on("pong", () => { socket.isAlive = true; });
  socket.on("close", (code) => removeClient(client, code));
  socket.on("error", () => {});
});

const heartbeatTimer = setInterval(() => {
  for (const socket of websocketServer.clients) {
    if (socket.isAlive === false) {
      socket.terminate();
      continue;
    }
    socket.isAlive = false;
    socket.ping();
  }
}, HEARTBEAT_MS);
heartbeatTimer.unref();

const cleanupTimer = setInterval(cleanupRooms, Math.min(60000, WAITING_ROOM_TTL_MS));
cleanupTimer.unref();

function handleMessage(client, buffer) {
  let message;
  try {
    message = JSON.parse(buffer.toString("utf8"));
  } catch {
    sendError(client.socket, "invalid_json", "Message must be valid JSON.");
    return;
  }
  if (message.type !== "ping") touchRoom(client.roomCode);

  switch (message.type) {
    case "resume_session":
      resumeSession(client, String(message.reconnect_token ?? ""));
      break;
    case "create_room":
      createRoom(client, cleanName(message.player_name));
      break;
    case "join_room":
      joinRoom(client, cleanCode(message.room_code), cleanName(message.player_name));
      break;
    case "join_random_queue":
      joinRandomQueue(client, cleanName(message.player_name));
      break;
    case "leave_random_queue":
      leaveRandomQueue(client);
      break;
    case "leave_room":
      leaveRoom(client);
      break;
    case "submit_loadout":
      submitLoadout(client, message.loadout);
      break;
    case "set_room_rules":
      setRoomRules(client, message.rules);
      break;
    case "choose_move":
      resolveTurn(client, String(message.move_id ?? ""));
      break;
    case "forfeit":
      forfeitMatch(client, "forfeit");
      break;
    case "ping":
      send(client.socket, { type: "pong", sent_at: message.sent_at ?? null });
      break;
    default:
      sendError(client.socket, "unknown_message", "Unknown message type.");
  }
}

function createRoom(client, playerName) {
  removeFromRandomQueue(client);
  leaveRoom(client, false);
  let code = createRoomCode();
  while (rooms.has(code)) code = createRoomCode();
  const room = {
    code,
    hostId: client.id,
    players: new Map(),
    match: null,
    rules: { allow_repeated_fixed_energy: false },
    updatedAt: Date.now()
  };
  rooms.set(code, room);
  addPlayer(room, client, playerName);
  send(client.socket, { type: "room_joined", player_id: client.id, room: serializeRoom(room) });
  broadcastRoom(room);
}

function joinRoom(client, code, playerName) {
  removeFromRandomQueue(client);
  const room = rooms.get(code);
  if (!room) {
    sendError(client.socket, "room_not_found", "Room not found.");
    return;
  }
  if (room.players.size >= MAX_PLAYERS && !room.players.has(client.id)) {
    sendError(client.socket, "room_full", "Room already has two players.");
    return;
  }
  leaveRoom(client, false);
  addPlayer(room, client, playerName);
  send(client.socket, { type: "room_joined", player_id: client.id, room: serializeRoom(room) });
  broadcastRoom(room);
}

function joinRandomQueue(client, playerName) {
  if (client.roomCode) {
    sendError(client.socket, "already_in_room", "Leave the current room before matchmaking.");
    return;
  }
  removeFromRandomQueue(client);
  client.name = playerName;
  while (randomQueue.length > 0) {
    const opponent = randomQueue.shift();
    if (!opponent || opponent === client || !opponent.connected || opponent.roomCode) continue;
    createRandomRoom(opponent, client);
    return;
  }
  randomQueue.push(client);
  send(client.socket, { type: "matchmaking_status", state: "searching" });
}

function leaveRandomQueue(client, notify = true) {
  const removed = removeFromRandomQueue(client);
  if (notify && removed) send(client.socket, { type: "matchmaking_status", state: "idle" });
}

function removeFromRandomQueue(client) {
  const index = randomQueue.indexOf(client);
  if (index < 0) return false;
  randomQueue.splice(index, 1);
  return true;
}

function createRandomRoom(firstClient, secondClient) {
  let code = createRoomCode();
  while (rooms.has(code)) code = createRoomCode();
  const room = {
    code,
    hostId: firstClient.id,
    players: new Map(),
    match: null,
    rules: { allow_repeated_fixed_energy: false },
    matchmaking: "random",
    updatedAt: Date.now()
  };
  rooms.set(code, room);
  addPlayer(room, firstClient, firstClient.name);
  addPlayer(room, secondClient, secondClient.name);
  for (const player of room.players.values()) {
    send(player.socket, { type: "matchmaking_status", state: "matched" });
    send(player.socket, { type: "room_joined", player_id: player.id, room: serializeRoom(room) });
  }
  broadcastRoom(room);
}

function addPlayer(room, client, playerName) {
  client.name = playerName;
  client.roomCode = room.code;
  room.players.set(client.id, client);
  client.loadout = null;
  client.connected = true;
  room.updatedAt = Date.now();
}

function sendConnected(client, resumed) {
  send(client.socket, {
    type: resumed ? "session_resumed" : "connected",
    player_id: client.id,
    reconnect_token: client.reconnectToken,
    protocol: 3,
    capabilities: ["random_matchmaking"]
  });
}

function resumeSession(client, reconnectToken) {
  let previous = null;
  let room = null;
  for (const candidateRoom of rooms.values()) {
    previous = [...candidateRoom.players.values()].find((player) =>
      player.reconnectToken === reconnectToken && !player.connected
    );
    if (previous) {
      room = candidateRoom;
      break;
    }
  }
  if (!previous || !room) {
    sendError(client.socket, "resume_failed", "The previous Online session is no longer available.");
    return;
  }
  if (previous.disconnectTimer) clearTimeout(previous.disconnectTimer);
  client.id = previous.id;
  client.reconnectToken = previous.reconnectToken;
  client.name = previous.name;
  client.roomCode = room.code;
  client.loadout = previous.loadout;
  client.connected = true;
  client.disconnectTimer = null;
  room.players.delete(previous.id);
  room.players.set(client.id, client);
  room.updatedAt = Date.now();
  sendConnected(client, true);
  send(client.socket, { type: "room_joined", player_id: client.id, room: serializeRoom(room) });
  broadcastRoom(room);
  if (room.match) sendMatchState(room, client);
  for (const player of room.players.values()) {
    if (player.id !== client.id && player.connected) {
      send(player.socket, {
        type: "opponent_reconnected",
        message: "Opponent reconnected. The match can continue."
      });
    }
  }
}

function sendMatchState(room, client) {
  const players = [...room.players.values()].map((player) => ({
    id: player.id,
    name: player.name,
    loadout: player.loadout
  }));
  send(client.socket, { type: "match_ready", room_code: room.code, players });
  send(client.socket, {
    type: "match_started",
    room_code: room.code,
    match: serializeMatch(room.match),
    players: players.map((player) => ({ id: player.id, name: player.name }))
  });
}

function setRoomRules(client, rawRules) {
  const room = rooms.get(client.roomCode);
  if (!room || room.hostId !== client.id || room.match) {
    sendError(client.socket, "room_rules_locked", "Only the host can change rules before the match.");
    return;
  }
  if (room.matchmaking === "random") {
    sendError(client.socket, "random_rules_locked", "Random matches use standardized rules.");
    return;
  }
  room.rules.allow_repeated_fixed_energy = Boolean(rawRules?.allow_repeated_fixed_energy);
  for (const player of room.players.values()) player.loadout = null;
  broadcastRoom(room);
}

function submitLoadout(client, rawLoadout) {
  const room = rooms.get(client.roomCode);
  if (!room || !room.players.has(client.id)) {
    sendError(client.socket, "not_in_room", "Join a room before submitting a loadout.");
    return;
  }
  if (room.match) {
    sendError(client.socket, "match_already_started", "This match has already started.");
    return;
  }
  const validation = validateLoadout(rawLoadout);
  if (!validation.ok) {
    sendError(client.socket, "invalid_loadout", validation.message);
    return;
  }
  if (!room.rules.allow_repeated_fixed_energy && hasRepeatedFixedEnergy(rawLoadout)) {
    sendError(client.socket, "repeated_fixed_energy", "Repeated Fixed Energy is disabled by the host.");
    return;
  }
  client.loadout = structuredClone(rawLoadout);
  broadcastRoom(room);
  if (room.players.size === MAX_PLAYERS && [...room.players.values()].every((player) => player.loadout)) {
    startMatch(room);
  }
}

function startMatch(room) {
  if (room.match) return;
  const players = [...room.players.values()];
  const coinHeads = randomBytes(1)[0] % 2 === 0;
  const firstPlayer = players[coinHeads ? 0 : 1];
  room.match = {
    id: randomBytes(12).toString("hex"),
    turn: 1,
    currentPlayerId: firstPlayer.id,
    phase: "awaiting_move",
    createdAt: Date.now(),
    winnerId: null,
    coinHeads,
    hp: Object.fromEntries(players.map((player) => [
      player.id,
      loadPokemon(player.loadout.pokemon_id).max_hp ?? 120
    ])),
    lastMoveByPlayer: {},
    lastTurnByPlayer: {},
    effects: Object.fromEntries(players.map((player) => [player.id, {
      incomingDamageModifier: 0,
      incomingDamageImmunity: false,
      energyDiceModifier: 0,
      forcedOrientation: null,
      kyokoroDisabled: false,
      lockedMoveId: null
    }]))
  };
  const revealedPlayers = players.map((player) => ({
    id: player.id,
    name: player.name,
    loadout: player.loadout
  }));
  const payload = {
    type: "match_ready",
    room_code: room.code,
    players: revealedPlayers
  };
  for (const player of room.players.values()) send(player.socket, payload);
  const startPayload = {
    type: "match_started",
    room_code: room.code,
    match: serializeMatch(room.match),
    players: revealedPlayers.map((player) => ({ id: player.id, name: player.name }))
  };
  for (const player of room.players.values()) send(player.socket, startPayload);
}

function leaveRoom(client, notify = true) {
  removeFromRandomQueue(client);
  if (!client.roomCode) return;
  const room = rooms.get(client.roomCode);
  client.roomCode = null;
  if (client.disconnectTimer) clearTimeout(client.disconnectTimer);
  client.disconnectTimer = null;
  if (!room) return;
  if (room.match?.phase !== "finished" && room.players.has(client.id)) {
    forfeitMatch(client, "disconnected", room);
  }
  room.players.delete(client.id);
  room.updatedAt = Date.now();
  if (room.players.size === 0) {
    rooms.delete(room.code);
  } else {
    if (room.hostId === client.id) room.hostId = room.players.keys().next().value;
    broadcastRoom(room);
  }
  if (notify && client.socket.readyState === WebSocket.OPEN) {
    send(client.socket, { type: "room_left" });
  }
}

function forfeitMatch(client, reason = "forfeit", knownRoom = null) {
  const room = knownRoom ?? rooms.get(client.roomCode);
  if (!room?.match || !room.players.has(client.id)) {
    if (!knownRoom) sendError(client.socket, "match_not_ready", "The Online battle is not ready.");
    return;
  }
  const match = room.match;
  if (match.phase === "finished") return;
  const winner = [...room.players.values()].find((player) => player.id !== client.id);
  if (!winner) return;
  match.phase = "finished";
  match.winnerId = winner.id;
  const payload = {
    type: "match_ended",
    room_code: room.code,
    reason,
    forfeiting_player_id: client.id,
    match: serializeMatch(match)
  };
  for (const player of room.players.values()) send(player.socket, payload);
}

function removeClient(client, closeCode = 1006) {
  if (!clients.has(client.socket)) return;
  clients.delete(client.socket);
  removeFromRandomQueue(client);
  if (closeCode === 1000) {
    leaveRoom(client, false);
    return;
  }
  client.connected = false;
  if (!client.roomCode) return;
  const room = rooms.get(client.roomCode);
  if (!room || !room.players.has(client.id)) return;
  room.updatedAt = Date.now();
  broadcastRoom(room);
  for (const player of room.players.values()) {
    if (player.id !== client.id && player.connected) {
      send(player.socket, {
        type: "opponent_reconnecting",
        grace_ms: RECONNECT_GRACE_MS,
        message: "Opponent disconnected. Waiting briefly for reconnection."
      });
    }
  }
  client.disconnectTimer = setTimeout(() => expireDisconnectedClient(client), RECONNECT_GRACE_MS);
  client.disconnectTimer.unref?.();
}

function expireDisconnectedClient(client) {
  if (client.connected || !client.roomCode) return;
  const room = rooms.get(client.roomCode);
  if (!room || room.players.get(client.id) !== client) return;
  if (room.match?.phase !== "finished") forfeitMatch(client, "disconnected", room);
  leaveRoom(client, false);
}

function touchRoom(code) {
  const room = code ? rooms.get(code) : null;
  if (room) room.updatedAt = Date.now();
}

function cleanupRooms() {
  const now = Date.now();
  for (const room of rooms.values()) {
    const ttl = room.match?.phase === "finished" ? FINISHED_ROOM_TTL_MS : WAITING_ROOM_TTL_MS;
    if (now - room.updatedAt < ttl) continue;
    for (const player of room.players.values()) {
      if (player.disconnectTimer) clearTimeout(player.disconnectTimer);
      player.roomCode = null;
      send(player.socket, { type: "room_expired" });
    }
    rooms.delete(room.code);
  }
}

function broadcastRoom(room) {
  const payload = { type: "room_updated", room: serializeRoom(room) };
  for (const player of room.players.values()) send(player.socket, payload);
}

function serializeRoom(room) {
  return {
    code: room.code,
    host_id: room.hostId,
    match_started: room.match !== null,
    rules: { ...room.rules },
    matchmaking: room.matchmaking ?? "private",
    max_players: MAX_PLAYERS,
    players: [...room.players.values()].map((player) => ({
      id: player.id,
      name: player.name,
      is_host: player.id === room.hostId,
      ready: player.loadout !== null,
      connected: player.connected
    }))
  };
}

function serializeMatch(match) {
  return {
    id: match.id,
    turn: match.turn,
    current_player_id: match.currentPlayerId,
    phase: match.phase,
    created_at: match.createdAt,
    winner_id: match.winnerId,
    coin_heads: match.coinHeads,
    hp: { ...match.hp },
    last_move_by_player: { ...match.lastMoveByPlayer }
  };
}

function resolveTurn(client, moveId) {
  const room = rooms.get(client.roomCode);
  if (!room?.match || !room.players.has(client.id)) {
    sendError(client.socket, "match_not_ready", "The Online battle is not ready.");
    return;
  }
  if ([...room.players.values()].some((player) => !player.connected)) {
    sendError(client.socket, "match_paused", "Wait for the opponent to reconnect.");
    return;
  }
  const match = room.match;
  const resolvedTurn = match.turn;
  if (match.phase !== "awaiting_move" || match.currentPlayerId !== client.id) {
    sendError(client.socket, "not_your_turn", "Wait for your turn.");
    return;
  }
  if (!client.loadout.move_card_ids.includes(moveId)) {
    sendError(client.socket, "move_not_in_loadout", "That Move is not in your loadout.");
    return;
  }
  if (match.effects[client.id]?.lockedMoveId === moveId) {
    sendError(client.socket, "move_locked", "That Move is locked for this turn.");
    return;
  }
  const defender = [...room.players.values()].find((player) => player.id !== client.id);
  if (!defender) return;
  let move;
  try {
    move = loadMove(moveId);
  } catch {
    sendError(client.socket, "move_not_found", "Move data could not be loaded.");
    return;
  }
  const moveNameId = move.move_name_id ?? moveId;
  if (match.lastMoveByPlayer[client.id] === moveNameId) {
    sendError(client.socket, "move_repeated", "The same Move cannot be used twice in a row.");
    return;
  }

  match.phase = "resolving";
  // Choosing a Move consumes its consecutive-use slot even when Enerkoro
  // payment fails. This mirrors BattleController.mark_move_used(). Store the
  // shared move-name identity rather than the physical card id as required by
  // the tabletop rule.
  match.lastMoveByPlayer[client.id] = moveNameId;
  const actorEffects = match.effects[client.id];
  const defenderEffects = match.effects[defender.id];
  // Official rule: the coin-toss winner rolls two Enerkoro on turn 1.
  // The server remains authoritative so both online clients see one result.
  const openingTurnModifier = match.turn === 1 ? -1 : 0;
  const energyDiceModifier = Number(actorEffects.energyDiceModifier ?? 0) + openingTurnModifier;
  actorEffects.energyDiceModifier = 0;
  const energyRoll = rollEnergyDice(client.loadout.energy_dice_setup, energyDiceModifier);
  const energyCounts = countEnergy(energyRoll);
  const energyMet = meetsEnergyCost(energyCounts, move.energy_cost ?? []);
  let orientation = null;
  let printedDamage = Number(move.printed_damage ?? 0);
  let charakoroBonus = 0;
  let weaknessBonus = 0;
  let damage = 0;
  let healing = 0;
  let recoil = 0;
  let opponentKyokoroOrientations = [];
  let additionalKyokoroOrientations = [];
  let opponentEnergyRoll = [];
  let repeatMoveCount = 0;
  // Next-owner-turn Charakoro statuses are consumed when the turn begins,
  // even if Enerkoro payment later fails and the Charakoro is not validated.
  // This keeps Headstand and Kyokoro-disable aligned with the local engine.
  const forcedOrientation = actorEffects.forcedOrientation;
  const kyokoroDisabled = actorEffects.kyokoroDisabled;
  actorEffects.forcedOrientation = null;
  actorEffects.kyokoroDisabled = false;

  // Enerkoro and Charakoro are physically rolled together. The Charakoro
  // face is always sent for presentation, but it only becomes a validated
  // orientation when the Enerkoro payment succeeds. Keeping these two values
  // separate prevents clients from accidentally activating face effects on
  // a failed Energy check while still showing the actual simultaneous roll.
  const charakoroRollOrientation = kyokoroDisabled
    ? null
    : forcedOrientation ?? rollCharakoro(client.loadout.pokemon_id);

  if (energyMet) {
    orientation = charakoroRollOrientation;
    const actionContext = { match, actorId: client.id, defenderId: defender.id };
    const matchedActions = expandConditionalActions(
      getMatchedActions(move, orientation),
      actionContext
    );
    const baseActions = expandConditionalActions(move.base_actions ?? [], actionContext);
    const allActions = [...baseActions, ...matchedActions];
    const copiedDamage = getCopiedPrintedDamage(baseActions, match, defender.id);
    if (copiedDamage !== null) printedDamage = copiedDamage;
    charakoroBonus = getActionDamageBonus(matchedActions, energyCounts);
    const actorKyokoro = resolveActorKyokoroEffect(
      move,
      orientation,
      client.loadout.pokemon_id,
      actionContext,
      energyCounts
    );
    additionalKyokoroOrientations = actorKyokoro.orientations;
    charakoroBonus += actorKyokoro.damageBonus;
    repeatMoveCount = actorKyokoro.repeatMoveCount;
    const opponentKyokoro = resolveOpponentKyokoroEffect(
      move,
      orientation,
      defender.loadout.pokemon_id
    );
    opponentKyokoroOrientations = opponentKyokoro.orientations;
    charakoroBonus += opponentKyokoro.damageBonus;
    const opponentEnergy = resolveOpponentEnergyEffect(
      move,
      orientation,
      defender.loadout.energy_dice_setup
    );
    opponentEnergyRoll = opponentEnergy.rolls;
    charakoroBonus += opponentEnergy.damageBonus;
    const defenderPokemon = loadPokemon(defender.loadout.pokemon_id);
    const ignoreWeakness = allActions.some((action) => action.opcode === "weakness.ignore_current");
    weaknessBonus = ignoreWeakness ? 0 : getWeaknessBonus(defenderPokemon, move.attack_type);
    damage = Math.max(0, printedDamage + charakoroBonus);
    for (const action of matchedActions) {
      if (action.opcode === "damage.set") damage = Math.max(0, Number(action.args?.amount ?? damage));
      if (action.opcode === "damage.multiply") damage = Math.max(0, Math.round(damage * Number(action.args?.factor ?? 1)));
    }
    damage += weaknessBonus;
    if (repeatMoveCount > 0) {
      damage += repeatMoveCount * Math.max(0, printedDamage + weaknessBonus);
    }
    if (defenderEffects.incomingDamageImmunity) damage = 0;
    else damage = Math.max(0, damage + Number(defenderEffects.incomingDamageModifier ?? 0));
    defenderEffects.incomingDamageImmunity = false;
    defenderEffects.incomingDamageModifier = 0;
    match.hp[defender.id] = Math.max(0, Number(match.hp[defender.id]) - damage);
    for (const action of allActions) {
      const args = action.args ?? {};
      if (action.opcode === "hp.restore" && (args.target ?? "self") === "self") healing += Number(args.amount ?? 0);
      if (action.opcode === "damage.recoil") recoil += Number(args.amount ?? 0);
      applyFutureEffect(match, client.id, defender.id, action, orientation);
    }
    const actorMaxHp = Number(loadPokemon(client.loadout.pokemon_id).max_hp ?? 120);
    match.hp[client.id] = Math.min(actorMaxHp, Math.max(0, Number(match.hp[client.id]) + healing - recoil));
    match.lastTurnByPlayer[client.id] = {
      moveId,
      moveNameId: move.move_name_id ?? moveId,
      printedDamage,
      energyMet: true,
      outcomeSuccess: matchedActions.length > 0
    };
    actorEffects.lockedMoveId = null;
    applyMoveLockEffect(move, orientation, defender, defenderEffects);
  }
  if (!energyMet) {
    match.lastTurnByPlayer[client.id] = {
      moveId,
      moveNameId: move.move_name_id ?? moveId,
      printedDamage,
      energyMet: false,
      outcomeSuccess: false
    };
    actorEffects.lockedMoveId = null;
  }

  if (match.hp[defender.id] <= 0 || match.hp[client.id] <= 0) {
    match.phase = "finished";
    match.winnerId = match.hp[defender.id] <= 0 && match.hp[client.id] > 0 ? client.id : defender.id;
  } else {
    match.turn += 1;
    match.currentPlayerId = defender.id;
    match.phase = "awaiting_move";
  }

  const payload = {
    type: "turn_resolved",
    room_code: room.code,
    actor_id: client.id,
    defender_id: defender.id,
    move_id: moveId,
    move_name_id: move.move_name_id ?? moveId,
    energy_roll: energyRoll,
    energy_counts: energyCounts,
    energy_met: energyMet,
    charakoro_roll_orientation: charakoroRollOrientation,
    charakoro_orientation: orientation,
    additional_kyokoro_orientations: additionalKyokoroOrientations,
    opponent_kyokoro_orientations: opponentKyokoroOrientations,
    opponent_energy_roll: opponentEnergyRoll,
    repeat_move_count: repeatMoveCount,
    printed_damage: printedDamage,
    charakoro_bonus: charakoroBonus,
    weakness_bonus: weaknessBonus,
    damage,
    healing,
    recoil,
    resolved_turn: resolvedTurn,
    energy_dice_modifier: energyDiceModifier,
    match: serializeMatch(match)
  };
  for (const player of room.players.values()) send(player.socket, payload);
}

function rollEnergyDice(setup, modifier = 0) {
  const count = Math.max(0, setup.dice.length + Number(modifier ?? 0));
  return Array.from({ length: count }, (_, index) => {
    const die = setup.dice[index % setup.dice.length];
    const face = randomBytes(1)[0] % 6;
    if (face < 2) return { face_type: "fixed", face_index: face, energies: [die.fixed[face]] };
    if (face < 4) return { face_type: "double", face_index: face - 2, energies: [...die.double[face - 2]] };
    return { face_type: "single", face_index: face - 4, energies: [die.single[face - 4]] };
  });
}

function countEnergy(rolls) {
  const counts = {};
  for (const roll of rolls) for (const energy of roll.energies) counts[energy] = (counts[energy] ?? 0) + 1;
  return counts;
}

function meetsEnergyCost(counts, costs) {
  const remaining = Object.fromEntries(
    Object.entries(counts ?? {}).map(([energyType, count]) => [
      energyType,
      Math.max(0, Number(count ?? 0))
    ])
  );
  let wildcardRequired = 0;

  // Match the game client: typed costs are paid first, then each remaining
  // Energy symbol may pay a Normal (wildcard) requirement.
  for (const cost of costs ?? []) {
    const energyType = String(cost?.energy_type ?? "");
    const required = Math.max(0, Number(cost?.count ?? 0));
    if (energyType === "normal") {
      wildcardRequired += required;
      continue;
    }
    const available = Math.max(0, Number(remaining[energyType] ?? 0));
    if (available < required) return false;
    remaining[energyType] = available - required;
  }

  const remainingTotal = Object.values(remaining)
    .reduce((sum, count) => sum + Math.max(0, Number(count ?? 0)), 0);
  return remainingTotal >= wildcardRequired;
}

function rollCharakoro(pokemonId) {
  const pokemon = loadPokemon(pokemonId);
  const profile = loadJson("database/kyokoro_profiles", `${safeId(pokemon.kyokoro_profile_id)}.json`);
  const weights = profile.orientation_weights ?? {};
  const total = ORIENTATIONS.reduce((sum, orientation) => sum + Number(weights[orientation] ?? 1), 0);
  let cursor = (randomBytes(4).readUInt32BE(0) / 0xffffffff) * total;
  for (const orientation of ORIENTATIONS) {
    cursor -= Number(weights[orientation] ?? 1);
    if (cursor <= 0) return orientation;
  }
  return ORIENTATIONS.at(-1);
}

function getMatchedActions(move, orientation) {
  if (!orientation) return [];
  const actions = [];
  for (const rule of move.outcome_rules ?? []) {
    const condition = rule.condition ?? {};
    if (condition.type === "kyokoro_orientation_any" && (condition.orientations ?? []).includes(orientation)) {
      actions.push(...(rule.actions ?? []));
    }
  }
  return actions;
}

function expandConditionalActions(actions, context) {
  const result = [];
  for (const action of actions ?? []) {
    if (action?.opcode !== "condition.if") {
      result.push(action);
      continue;
    }
    const branch = evaluateCondition(action.args?.condition ?? {}, context)
      ? action.then ?? []
      : action.else ?? [];
    result.push(...expandConditionalActions(branch, context));
  }
  return result;
}

function evaluateCondition(condition, context) {
  const { match, actorId, defenderId } = context;
  const type = condition.type;
  if (type === "hp") {
    const targetId = (condition.target ?? "self") === "opponent" ? defenderId : actorId;
    const actual = Number(match.hp[targetId] ?? 0);
    const expected = Number(condition.value ?? 0);
    const operator = condition.operator ?? "<=";
    if (operator === "<=") return actual <= expected;
    if (operator === "<") return actual < expected;
    if (operator === ">=") return actual >= expected;
    if (operator === ">") return actual > expected;
    if (operator === "==") return actual === expected;
    return false;
  }
  if (type === "previous_self_energy_failed") {
    return match.lastTurnByPlayer[actorId]?.energyMet === false;
  }
  if (type === "previous_opponent_energy_failed") {
    return match.lastTurnByPlayer[defenderId]?.energyMet === false;
  }
  if (type === "previous_self_move_outcome_success") {
    const previous = match.lastTurnByPlayer[actorId];
    return Boolean(previous?.outcomeSuccess)
      && (!condition.move_name_id || previous.moveNameId === condition.move_name_id);
  }
  return false;
}

function getCopiedPrintedDamage(actions, match, defenderId) {
  if (!(actions ?? []).some((action) => action.opcode === "damage.copy_previous_opponent_move")) {
    return null;
  }
  const value = match.lastTurnByPlayer[defenderId]?.printedDamage;
  return Number.isFinite(Number(value)) ? Number(value) : 0;
}

function resolveActorKyokoroEffect(move, initialOrientation, pokemonId, context, energyCounts) {
  const result = { orientations: [], damageBonus: 0, repeatMoveCount: 0 };
  if (!initialOrientation) return result;
  const effect = (move.special_effects ?? []).find((candidate) => [
    "kyokoro.multi_roll",
    "kyokoro.repeat_until_fail",
    "kyokoro.repeat_same_move_until_fail"
  ].includes(candidate?.effect_type));
  if (!effect) return result;

  const successOrientations = effect.confirmed_orientations
    ?? getOutcomeSuccessOrientations(move);
  if (effect.effect_type !== "kyokoro.multi_roll" && !successOrientations.includes(initialOrientation)) {
    return result;
  }
  if (effect.effect_type === "kyokoro.multi_roll") {
    const extraCount = Math.max(0, Number(effect.roll_count ?? 1) - 1);
    for (let index = 0; index < extraCount; index += 1) {
      const orientation = rollCharakoro(pokemonId);
      result.orientations.push(orientation);
      const actions = expandConditionalActions(getMatchedActions(move, orientation), context);
      result.damageBonus += getActionDamageBonus(actions, energyCounts);
    }
    return result;
  }
  for (let index = 0; index < 64; index += 1) {
    const orientation = rollCharakoro(pokemonId);
    result.orientations.push(orientation);
    if (!successOrientations.includes(orientation)) break;
    if (effect.effect_type === "kyokoro.repeat_same_move_until_fail") {
      result.repeatMoveCount += 1;
    } else {
      const actions = expandConditionalActions(getMatchedActions(move, orientation), context);
      result.damageBonus += getActionDamageBonus(actions, energyCounts);
    }
  }
  return result;
}

function getOutcomeSuccessOrientations(move) {
  const result = [];
  for (const rule of move.outcome_rules ?? []) {
    if (rule.condition?.type === "kyokoro_orientation_any") {
      result.push(...(rule.condition.orientations ?? []));
    }
  }
  return [...new Set(result)];
}

function resolveOpponentKyokoroEffect(move, initialOrientation, defenderPokemonId) {
  const result = { orientations: [], damageBonus: 0 };
  if (!initialOrientation) return result;
  const effect = (move.special_effects ?? []).find((candidate) =>
    candidate?.effect_type === "kyokoro.opponent_roll"
    && (candidate.confirmed_orientations ?? []).includes(initialOrientation)
  );
  if (!effect) return result;
  const rollCount = Math.max(1, Number(effect.roll_count ?? 1));
  const successOrientations = effect.opponent_success_orientations ?? [];
  const successActions = effect.opponent_success_actions ?? [];
  for (let index = 0; index < rollCount; index += 1) {
    const rolledOrientation = rollCharakoro(defenderPokemonId);
    result.orientations.push(rolledOrientation);
    if (successOrientations.includes(rolledOrientation)) {
      result.damageBonus += getActionDamageBonus(successActions, {});
    }
  }
  return result;
}

function resolveOpponentEnergyEffect(move, initialOrientation, defenderSetup) {
  const result = { rolls: [], damageBonus: 0 };
  const effect = (move.special_effects ?? []).find((candidate) =>
    candidate?.effect_type === "energy_dice.opponent_roll"
    && (candidate.confirmed_orientations ?? []).includes(initialOrientation)
  );
  if (!effect) return result;
  const modifier = Math.max(0, Number(effect.roll_count ?? 3) - 3);
  result.rolls = rollEnergyDice(defenderSetup, modifier);
  const counts = countEnergy(result.rolls);
  const highest = Math.max(0, ...Object.values(counts).map(Number));
  const tiedTotal = Object.values(counts)
    .map(Number)
    .filter((count) => count === highest)
    .reduce((sum, count) => sum + count, 0);
  result.damageBonus = tiedTotal * Number(effect.damage_per_most_common_energy ?? 0);
  return result;
}

function applyMoveLockEffect(move, orientation, defender, defenderEffects) {
  const effect = (move.special_effects ?? []).find((candidate) =>
    candidate?.effect_type === "move.select_and_lock"
    && (candidate.confirmed_orientations ?? []).includes(orientation)
  );
  if (!effect) return;
  let selected = null;
  let selectedDamage = -1;
  for (const moveId of defender.loadout.move_card_ids ?? []) {
    const candidate = loadMove(moveId);
    const damage = Number(candidate.printed_damage ?? 0);
    if (damage > selectedDamage) {
      selected = moveId;
      selectedDamage = damage;
    }
  }
  defenderEffects.lockedMoveId = selected;
}

function getActionDamageBonus(actions, energyCounts) {
  let bonus = 0;
  for (const action of actions) {
    if (action.opcode === "damage.add" && (action.args?.target ?? "opponent") === "opponent") bonus += Number(action.args?.amount ?? 0);
    if (action.opcode === "damage.add_per_energy") {
      bonus += Number(energyCounts[action.args?.energy_type] ?? 0) * Number(action.args?.amount_per_energy ?? 0);
    }
  }
  return bonus;
}

function applyFutureEffect(match, actorId, defenderId, action, orientation) {
  const args = action.args ?? {};
  const targetId = (args.target ?? "self") === "opponent" ? defenderId : actorId;
  const effects = match.effects[targetId];
  if (action.opcode === "incoming_damage.modify") effects.incomingDamageModifier += Number(args.amount ?? 0);
  if (action.opcode === "incoming_damage.immunity") effects.incomingDamageImmunity = true;
  if (action.opcode === "energy_dice.modify") effects.energyDiceModifier += Number(args.amount ?? 0);
  if (action.opcode === "kyokoro.force_next_orientation") {
    effects.forcedOrientation = args.orientation === "current" ? orientation : args.orientation;
  }
  if (action.opcode === "status.add" && args.status_type === "kyokoro_disable") effects.kyokoroDisabled = true;
}

function getWeaknessBonus(pokemon, attackType) {
  const weakness = (pokemon.weaknesses ?? []).find((entry) => entry.attack_type === attackType);
  return Number(weakness?.bonus_damage ?? 0);
}

function loadMove(id) { return loadJson("database/move_cards", `${safeId(id)}.json`); }
function loadPokemon(id) { return loadJson("database/pokemon", `${safeId(id)}.json`); }
function loadJson(directory, filename) { return JSON.parse(readFileSync(resolve(REPOSITORY_ROOT, directory, filename), "utf8")); }
function safeId(value) {
  const id = String(value ?? "");
  if (!/^[a-zA-Z0-9_-]+$/.test(id)) throw new Error("Invalid content id");
  return id;
}

function send(socket, payload) {
  if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(payload));
}

function sendError(socket, code, message) {
  send(socket, { type: "error", code, message });
}

function cleanName(value) {
  const name = String(value ?? "Player").trim().slice(0, 24);
  return name || "Player";
}

function cleanCode(value) {
  return String(value ?? "").trim().toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, ROOM_CODE_LENGTH);
}

function createRoomCode() {
  // A-I map one-to-one to the nine Energy icons in the client. Keeping the
  // transport as a six-character string avoids changing the room protocol.
  const alphabet = "ABCDEFGHI";
  const bytes = randomBytes(ROOM_CODE_LENGTH);
  return [...bytes].map((byte) => alphabet[byte % alphabet.length]).join("");
}

function validateLoadout(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return { ok: false, message: "Loadout must be an object." };
  }
  if (typeof value.pokemon_id !== "string" || !value.pokemon_id.trim()) {
    return { ok: false, message: "Loadout requires a Pokémon." };
  }
  if (!Array.isArray(value.move_card_ids) || value.move_card_ids.length !== 4) {
    return { ok: false, message: "Loadout requires exactly four Moves." };
  }
  if (new Set(value.move_card_ids).size !== 4 || value.move_card_ids.some((id) => typeof id !== "string" || !id.trim())) {
    return { ok: false, message: "Loadout Moves must be four different valid ids." };
  }
  const dice = value.energy_dice_setup?.dice;
  if (!Array.isArray(dice) || dice.length !== 3) {
    return { ok: false, message: "Loadout requires exactly three Enerkoro." };
  }
  const validEnergyList = (list, size) => Array.isArray(list) && list.length === size
    && list.every((energy) => typeof energy === "string" && energy.trim());
  const validDie = (die) => die && typeof die === "object"
    && validEnergyList(die.fixed, 2)
    && Array.isArray(die.double) && die.double.length === 2
    && die.double.every((face) => validEnergyList(face, 2))
    && validEnergyList(die.single, 2);
  if (!dice.every(validDie)) {
    return { ok: false, message: "Each Enerkoro requires two Fixed, Double, and Single faces." };
  }
  try {
    loadPokemon(value.pokemon_id);
    for (const moveId of value.move_card_ids) loadMove(moveId);
  } catch {
    return { ok: false, message: "Loadout references unavailable content." };
  }
  return { ok: true };
}

function hasRepeatedFixedEnergy(loadout) {
  const seen = new Set();
  for (const die of loadout.energy_dice_setup?.dice ?? []) {
    for (const energy of die.fixed ?? []) {
      if (seen.has(energy)) return true;
      seen.add(energy);
    }
  }
  return false;
}

server.listen(PORT, "0.0.0.0", () => {
  console.log(`PLAKORO online server listening on 0.0.0.0:${PORT}`);
});
