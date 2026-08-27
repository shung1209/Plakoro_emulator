import { createServer } from "node:http";
import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { WebSocket, WebSocketServer } from "ws";

const PORT = Number.parseInt(process.env.PORT ?? "10000", 10);
const ROOM_CODE_LENGTH = 6;
const MAX_PLAYERS = 2;
const REPOSITORY_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const ORIENTATIONS = ["FACE_DOWN", "FACE_UP", "HEAD_UP", "HEAD_DOWN", "HEAD_LEFT", "HEAD_RIGHT"];
const rooms = new Map();
const clients = new Map();

const server = createServer((request, response) => {
  if (request.url === "/health") {
    response.writeHead(200, { "content-type": "application/json" });
    response.end(JSON.stringify({ ok: true, rooms: rooms.size }));
    return;
  }
  response.writeHead(200, { "content-type": "application/json" });
  response.end(JSON.stringify({
    service: "plakoro-online",
    protocol: 1,
    websocket: "/ws"
  }));
});

const websocketServer = new WebSocketServer({ server, path: "/ws" });

websocketServer.on("connection", (socket) => {
  const client = {
    id: randomBytes(8).toString("hex"),
    name: "Player",
    roomCode: null,
    socket
  };
  clients.set(socket, client);
  send(socket, { type: "connected", player_id: client.id, protocol: 1 });

  socket.on("message", (buffer) => handleMessage(client, buffer));
  socket.on("close", () => removeClient(client));
  socket.on("error", () => removeClient(client));
});

function handleMessage(client, buffer) {
  let message;
  try {
    message = JSON.parse(buffer.toString("utf8"));
  } catch {
    sendError(client.socket, "invalid_json", "Message must be valid JSON.");
    return;
  }

  switch (message.type) {
    case "create_room":
      createRoom(client, cleanName(message.player_name));
      break;
    case "join_room":
      joinRoom(client, cleanCode(message.room_code), cleanName(message.player_name));
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
  leaveRoom(client, false);
  let code = createRoomCode();
  while (rooms.has(code)) code = createRoomCode();
  const room = {
    code,
    hostId: client.id,
    players: new Map(),
    match: null,
    rules: { allow_repeated_fixed_energy: false }
  };
  rooms.set(code, room);
  addPlayer(room, client, playerName);
  send(client.socket, { type: "room_joined", player_id: client.id, room: serializeRoom(room) });
  broadcastRoom(room);
}

function joinRoom(client, code, playerName) {
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

function addPlayer(room, client, playerName) {
  client.name = playerName;
  client.roomCode = room.code;
  room.players.set(client.id, client);
  client.loadout = null;
}

function setRoomRules(client, rawRules) {
  const room = rooms.get(client.roomCode);
  if (!room || room.hostId !== client.id || room.match) {
    sendError(client.socket, "room_rules_locked", "Only the host can change rules before the match.");
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
    effects: Object.fromEntries(players.map((player) => [player.id, {
      incomingDamageModifier: 0,
      incomingDamageImmunity: false,
      energyDiceModifier: 0,
      forcedOrientation: null,
      kyokoroDisabled: false
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
  if (!client.roomCode) return;
  const room = rooms.get(client.roomCode);
  client.roomCode = null;
  if (!room) return;
  if (room.match?.phase !== "finished" && room.players.has(client.id)) {
    forfeitMatch(client, "disconnected", room);
  }
  room.players.delete(client.id);
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

function removeClient(client) {
  if (!clients.has(client.socket)) return;
  leaveRoom(client, false);
  clients.delete(client.socket);
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
    max_players: MAX_PLAYERS,
    players: [...room.players.values()].map((player) => ({
      id: player.id,
      name: player.name,
      is_host: player.id === room.hostId,
      ready: player.loadout !== null
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
    hp: { ...match.hp }
  };
}

function resolveTurn(client, moveId) {
  const room = rooms.get(client.roomCode);
  if (!room?.match || !room.players.has(client.id)) {
    sendError(client.socket, "match_not_ready", "The Online battle is not ready.");
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
  if (match.lastMoveByPlayer[client.id] === moveId) {
    sendError(client.socket, "move_repeated", "The same Move cannot be used twice in a row.");
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

  match.phase = "resolving";
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

  if (energyMet) {
    if (!actorEffects.kyokoroDisabled) {
      orientation = actorEffects.forcedOrientation ?? rollCharakoro(client.loadout.pokemon_id);
    }
    actorEffects.forcedOrientation = null;
    actorEffects.kyokoroDisabled = false;
    const matchedActions = getMatchedActions(move, orientation);
    const allActions = [...(move.base_actions ?? []), ...matchedActions];
    charakoroBonus = getActionDamageBonus(matchedActions, energyCounts);
    const defenderPokemon = loadPokemon(defender.loadout.pokemon_id);
    const ignoreWeakness = allActions.some((action) => action.opcode === "weakness.ignore_current");
    weaknessBonus = ignoreWeakness ? 0 : getWeaknessBonus(defenderPokemon, move.attack_type);
    damage = Math.max(0, printedDamage + charakoroBonus);
    for (const action of matchedActions) {
      if (action.opcode === "damage.set") damage = Math.max(0, Number(action.args?.amount ?? damage));
      if (action.opcode === "damage.multiply") damage = Math.max(0, Math.round(damage * Number(action.args?.factor ?? 1)));
    }
    damage += weaknessBonus;
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
    match.lastMoveByPlayer[client.id] = moveId;
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
    charakoro_orientation: orientation,
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
  return costs.every((cost) => Number(counts[cost.energy_type] ?? 0) >= Number(cost.count ?? 0));
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
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
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
