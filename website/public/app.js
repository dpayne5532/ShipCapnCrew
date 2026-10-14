// Playable Ship Cap'n Crew demo — mirrors the iOS GameModel rules.
(() => {
  const tray = document.getElementById("tray");
  if (!tray) return;

  const PIPS = {
    1: ["c"],
    2: ["tl", "br"],
    3: ["tl", "c", "br"],
    4: ["tl", "tr", "bl", "br"],
    5: ["tl", "tr", "c", "bl", "br"],
    6: ["tl", "tr", "ml", "mr", "bl", "br"],
  };
  const MAX_ROLLS = 3;

  const state = {
    dice: [1, 1, 1, 1, 1],
    held: [false, false, false, false, false],
    rollNumber: 0,
    freeRoll: false,
  };

  const $ = (id) => document.getElementById(id);
  const rollBtn = $("roll");
  const holdAllBtn = $("hold-all");
  const freeBtn = $("free-roll");
  const status = $("status");

  const buttons = state.dice.map((_, i) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "die-btn";
    btn.innerHTML = '<div class="die"></div><span class="state"></span>';
    btn.addEventListener("click", () => {
      state.held[i] = !state.held[i];
      render();
    });
    tray.appendChild(btn);
    return btn;
  });

  const turnOver = () => !state.freeRoll && state.rollNumber >= MAX_ROLLS;

  function cargo() {
    const rest = [...state.dice];
    for (const needed of [6, 5, 4]) {
      const i = rest.indexOf(needed);
      if (i === -1) return null;
      rest.splice(i, 1);
    }
    return rest[0] + rest[1];
  }

  function render() {
    buttons.forEach((btn, i) => {
      const die = btn.firstElementChild;
      const value = state.dice[i];
      const held = state.held[i];
      die.classList.toggle("red", held);
      die.innerHTML = PIPS[value].map((p) => `<i class="${p}"></i>`).join("");
      btn.lastElementChild.textContent = held ? "HELD" : "ROLLING";
      btn.setAttribute("aria-pressed", String(held));
      btn.setAttribute("aria-label", `Die ${i + 1}, showing ${value}, ${held ? "held" : "rolling"}`);
    });

    $("roll-num").textContent = state.rollNumber;
    $("roll-max").textContent = state.freeRoll ? "/∞" : `/${MAX_ROLLS}`;
    [...$("bars").children].forEach((bar, i) => {
      bar.classList.toggle("on", !state.freeRoll && i < state.rollNumber);
    });

    const rolled = state.rollNumber > 0;
    for (const v of [6, 5, 4]) {
      $(`chip-${v}`).classList.toggle("lit", rolled && state.dice.includes(v));
    }
    const c = rolled ? cargo() : null;
    $("cargo").textContent = c ?? "–";
    $("chip-cargo").classList.toggle("lit", c !== null);

    const over = turnOver();
    rollBtn.textContent = over ? "NEW TURN" : "ROLL";
    rollBtn.classList.toggle("over", over);
    const allHeld = state.held.every(Boolean);
    holdAllBtn.textContent = allHeld ? "Roll all" : "Hold all";
    freeBtn.textContent = `Free Roll: ${state.freeRoll ? "on" : "off"}`;
    freeBtn.setAttribute("aria-pressed", String(state.freeRoll));

    if (!rolled) status.textContent = "Tap ROLL to throw the dice.";
    else if (c !== null) status.textContent = over ? `Sailing with ${c} cargo!` : `Ship, Cap'n and Crew! Cargo is ${c}. Keep it or reroll the other two.`;
    else if (over) status.textContent = "No crew, no cargo. This turn scores zero.";
    else status.textContent = "Tap dice to hold them, then roll again.";
  }

  rollBtn.addEventListener("click", () => {
    if (turnOver()) {
      state.dice = [1, 1, 1, 1, 1];
      state.held = [false, false, false, false, false];
      state.rollNumber = 0;
      render();
      return;
    }
    state.dice.forEach((_, i) => {
      if (state.held[i]) return;
      state.dice[i] = 1 + Math.floor(Math.random() * 6);
      const die = buttons[i].firstElementChild;
      die.classList.remove("spin");
      void die.offsetWidth; // restart the animation
      die.classList.add("spin");
    });
    state.rollNumber += 1;
    render();
  });

  holdAllBtn.addEventListener("click", () => {
    const value = !state.held.every(Boolean);
    state.held = state.held.map(() => value);
    render();
  });

  freeBtn.addEventListener("click", () => {
    state.freeRoll = !state.freeRoll;
    if (!state.freeRoll) state.rollNumber = Math.min(state.rollNumber, MAX_ROLLS);
    render();
  });

  render();
})();
