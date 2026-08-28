import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { setTimeout as delay } from "node:timers/promises";
import { WebSocket } from "ws";

const port = 18127;
const server = spawn(process.execPath, ["src/server.js"], {
  cwd: new URL("..", import.meta.url),
  env: {
    ...process.env,
    PORT: String(port),
    RECONNECT_GRACE_MS: "180",
    WAITING_ROOM_TTL_MS: "300",
    FINISHED_ROOM_TTL_MS: "300",
    HEARTBEAT_MS: "1000"
  },
  stdio: ["ignore", "pipe", "inherit"]
});

const loadout = {
  pokemon_id: "charmander_standard",
  move_card_ids: [
    "charmander_ember_stw02_001",
    "charmander_fire_fang_stw02_004",
    "charmander_flame_up_stw02_000",
    "charmander_flamethrower_stw02_003"
  ],
  energy_dice_setup: {
    dice: [
      { fixed: ["fire", "water"], double: [["fire", "fire"], ["fire", "water"]], single: ["fire", "water"] },
      { fixed: ["grass", "electric"], double: [["fire", "grass"], ["fire", "electric"]], single: ["fire", "grass"] },
      { fixed: ["psychic", "fighting"], double: [["fire", "psychic"], ["fire", "fighting"]], single: ["fire", "psychic"] }
    ]
  }
};

function connectClient() {
  const socket = new WebSocket(`ws://127.0.0.1:${port}/ws`);
  const messages = [];
  const waiters = [];
  socket.on("message", (data) => {
    const message = JSON.parse(data.toString());
    messages.push(message);
    for (const waiter of [...waiters]) waiter();
  });
  return {
    socket,
    send: (message) => socket.send(JSON.stringify(message)),
    async next(type, timeoutMs = 3000) {
      const deadline = Date.now() + timeoutMs;
      while (Date.now() < deadline) {
        const errorIndex = messages.findIndex((message) => message.type === "error");
        if (errorIndex >= 0) {
          const error = messages.splice(errorIndex, 1)[0];
          throw new Error(`Server error ${error.code}: ${error.message}`);
        }
        const index = messages.findIndex((message) => message.type === type);
        if (index >= 0) return messages.splice(index, 1)[0];
        await new Promise((resolve, reject) => {
          const timer = setTimeout(() => {
            const waiterIndex = waiters.indexOf(wake);
            if (waiterIndex >= 0) waiters.splice(waiterIndex, 1);
            reject(new Error(`Timed out waiting for ${type}`));
          }, Math.min(250, Math.max(1, deadline - Date.now())));
          const wake = () => {
            clearTimeout(timer);
            const waiterIndex = waiters.indexOf(wake);
            if (waiterIndex >= 0) waiters.splice(waiterIndex, 1);
            resolve();
          };
          waiters.push(wake);
        }).catch(() => {});
      }
      throw new Error(`Timed out waiting for ${type}`);
    }
  };
}

async function createStartedMatch() {
  const playerOne = connectClient();
  const playerTwo = connectClient();
  const connectedOne = await playerOne.next("connected");
  const connectedTwo = await playerTwo.next("connected");
  playerOne.id = connectedOne.player_id;
  playerTwo.id = connectedTwo.player_id;
  playerOne.reconnectToken = connectedOne.reconnect_token;
  playerTwo.reconnectToken = connectedTwo.reconnect_token;
  playerOne.send({ type: "create_room", player_name: "Player" });
  const joined = await playerOne.next("room_joined");
  playerTwo.send({ type: "join_room", room_code: joined.room.code, player_name: "Player" });
  await playerTwo.next("room_joined");
  playerOne.send({ type: "submit_loadout", loadout });
  playerTwo.send({ type: "submit_loadout", loadout });
  const [startedOne, startedTwo] = await Promise.all([
    playerOne.next("match_started"),
    playerTwo.next("match_started")
  ]);
  assert.deepEqual(startedOne.match, startedTwo.match);
  return { playerOne, playerTwo, match: startedOne.match };
}

async function run() {
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("Server did not start")), 3000);
    server.stdout.on("data", (data) => {
      if (data.toString().includes("listening")) {
        clearTimeout(timer);
        resolve();
      }
    });
  });

  const cancelledSearch = connectClient();
  await cancelledSearch.next("connected");
  cancelledSearch.send({ type: "join_random_queue", player_name: "Queued Player" });
  assert.equal((await cancelledSearch.next("matchmaking_status")).state, "searching");
  cancelledSearch.send({ type: "leave_random_queue" });
  assert.equal((await cancelledSearch.next("matchmaking_status")).state, "idle");
  cancelledSearch.socket.close();

  const randomOne = connectClient();
  const randomTwo = connectClient();
  await Promise.all([randomOne.next("connected"), randomTwo.next("connected")]);
  randomOne.send({ type: "join_random_queue", player_name: "Random One" });
  assert.equal((await randomOne.next("matchmaking_status")).state, "searching");
  randomTwo.send({ type: "join_random_queue", player_name: "Random Two" });
  const [randomJoinedOne, randomJoinedTwo] = await Promise.all([
    randomOne.next("room_joined"),
    randomTwo.next("room_joined")
  ]);
  assert.equal(randomJoinedOne.room.code, randomJoinedTwo.room.code);
  assert.equal(randomJoinedOne.room.matchmaking, "random");
  assert.equal(randomJoinedOne.room.players.length, 2);
  assert.equal(randomJoinedOne.room.rules.allow_repeated_fixed_energy, false);
  randomOne.send({ type: "leave_room" });
  await randomOne.next("room_left");
  randomTwo.send({ type: "leave_room" });
  await randomTwo.next("room_left");
  randomOne.socket.close();
  randomTwo.socket.close();

  const forfeited = await createStartedMatch();
  forfeited.playerOne.send({ type: "forfeit" });
  const [loserResult, winnerResult] = await Promise.all([
    forfeited.playerOne.next("match_ended"),
    forfeited.playerTwo.next("match_ended")
  ]);
  assert.equal(loserResult.reason, "forfeit");
  assert.equal(winnerResult.match.phase, "finished");
  assert.equal(winnerResult.forfeiting_player_id, forfeited.playerOne.id);
  assert.equal(winnerResult.match.winner_id, forfeited.playerTwo.id);
  forfeited.playerOne.send({ type: "leave_room" });
  await forfeited.playerOne.next("room_left");
  forfeited.playerTwo.send({ type: "leave_room" });
  await forfeited.playerTwo.next("room_left");
  forfeited.playerOne.socket.close();
  forfeited.playerTwo.socket.close();

  const resumed = await createStartedMatch();
  resumed.playerOne.socket.close();
  await delay(30);
  resumed.playerTwo.send({
    type: "choose_move",
    move_id: loadout.move_card_ids[0]
  });
  await assert.rejects(
    () => resumed.playerTwo.next("turn_resolved"),
    /match_paused/,
    "The match must pause while a player is inside the reconnect grace period"
  );
  const replacement = connectClient();
  await replacement.next("connected");
  replacement.send({
    type: "resume_session",
    reconnect_token: resumed.playerOne.reconnectToken
  });
  const resumedIdentity = await replacement.next("session_resumed");
  const resumedMatch = await replacement.next("match_started");
  assert.equal(resumedIdentity.player_id, resumed.playerOne.id);
  assert.equal(resumedMatch.match.id, resumed.match.id);
  assert.equal(resumedMatch.match.current_player_id, resumed.match.current_player_id);
  replacement.socket.close();
  resumed.playerTwo.socket.close();

  const disconnected = await createStartedMatch();
  disconnected.playerOne.socket.close();
  const disconnectResult = await disconnected.playerTwo.next("match_ended");
  assert.equal(disconnectResult.reason, "disconnected");
  assert.equal(disconnectResult.match.phase, "finished");
  assert.equal(disconnectResult.match.winner_id, disconnected.playerTwo.id);
  disconnected.playerTwo.socket.close();

  const natural = await createStartedMatch();
  const clientsById = new Map([
    [natural.playerOne.id, natural.playerOne],
    [natural.playerTwo.id, natural.playerTwo]
  ]);
  const lastSuccessfulMoveById = new Map();
  let match = natural.match;
  let finalOne;
  let finalTwo;
  for (let turn = 0; turn < 80 && match.phase !== "finished"; turn += 1) {
    const actor = clientsById.get(match.current_player_id);
    assert.ok(actor, "The authoritative current player must be connected");
    const previousMove = lastSuccessfulMoveById.get(actor.id);
    const selectedMove = previousMove === loadout.move_card_ids[0]
      ? loadout.move_card_ids[2]
      : loadout.move_card_ids[0];
    actor.send({
      type: "choose_move",
      move_id: selectedMove
    });
    [finalOne, finalTwo] = await Promise.all([
      natural.playerOne.next("turn_resolved"),
      natural.playerTwo.next("turn_resolved")
    ]);
    assert.deepEqual(finalOne.match, finalTwo.match);
    lastSuccessfulMoveById.set(actor.id, selectedMove);
    match = finalOne.match;
  }
  assert.equal(match.phase, "finished", "A normal match must eventually finish at zero HP");
  assert.ok(match.winner_id === natural.playerOne.id || match.winner_id === natural.playerTwo.id);
  assert.equal(finalOne.match.winner_id, finalTwo.match.winner_id);
  natural.playerOne.send({ type: "leave_room" });
  await natural.playerOne.next("room_left");
  natural.playerTwo.send({ type: "leave_room" });
  await natural.playerTwo.next("room_left");
  natural.playerOne.socket.close();
  natural.playerTwo.socket.close();

  const idle = connectClient();
  await idle.next("connected");
  idle.send({ type: "create_room", player_name: "Idle Player" });
  await idle.next("room_joined");
  await idle.next("room_expired", 1500);
  idle.socket.close();

  await delay(50);
  console.log("Online lifecycle tests passed: random matchmaking, reconnect, disconnect, cleanup, forfeit, and HP-zero sync.");
}

try {
  await run();
} finally {
  server.kill("SIGTERM");
}
