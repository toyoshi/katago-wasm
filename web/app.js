import createKataGo from "./assets/katago.js";

const statusValue = document.querySelector("#status-value");
const progressValue = document.querySelector("#progress-value");
const resultRow = document.querySelector("#result-row");
const resultValue = document.querySelector("#result-value");
const runButton = document.querySelector("#btn-run");
const clearButton = document.querySelector("#btn-clear");
const saveButton = document.querySelector("#btn-save-log");
const logOutput = document.querySelector("#log-output");
const humanMode = new URLSearchParams(window.location.search).get("mode") === "human";

let module;
let running = false;
let logLines = [];

function appendLog(value, level = "info") {
  const text = String(value).trimEnd();
  if (!text) return;

  logLines.push(text);
  const line = document.createElement("span");
  line.className = `log-line log-${level}`;
  line.textContent = text;
  logOutput.appendChild(line);
  logOutput.scrollTop = logOutput.scrollHeight;

  const match = text.match(/visits\/s\s*=\s*([0-9.]+)/);
  if (match) {
    resultValue.textContent = `${Number(match[1]).toFixed(2)} visits/s`;
    resultRow.hidden = false;
  }
  if (text.includes('"humanPolicy"')) {
    resultValue.textContent = "HumanSL policy returned";
    resultRow.hidden = false;
  }
}

function setStatus(label, detail) {
  statusValue.textContent = label;
  progressValue.textContent = detail;
}

async function fetchBytes(path) {
  const response = await fetch(path);
  if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
  return new Uint8Array(await response.arrayBuffer());
}

async function initialize() {
  if (!crossOriginIsolated || typeof SharedArrayBuffer === "undefined") {
    throw new Error("Cross-origin isolation is required for WebAssembly threads");
  }

  const query = humanMode ? `${JSON.stringify({
    id: "human-browser",
    moves: [],
    rules: "japanese",
    komi: 6.5,
    boardXSize: 9,
    boardYSize: 9,
    analyzeTurns: [0],
    maxVisits: 1,
    includePolicy: true,
    overrideSettings: { humanSLProfile: "preaz_5k" },
  })}\n` : "";
  const stdin = new TextEncoder().encode(query);
  let stdinOffset = 0;

  setStatus("LOADING", "WebAssembly module");
  module = await createKataGo({
    locateFile: (path) => `./assets/${path}`,
    stdin: () => stdinOffset < stdin.length ? stdin[stdinOffset++] : null,
    print: (text) => appendLog(text),
    printErr: (text) => appendLog(text, "warn"),
    onExit: (code) => {
      running = false;
      runButton.disabled = true;
      setStatus(code === 0 ? "DONE" : "ERROR", `Exit code ${code}`);
    },
  });

  setStatus("LOADING", "Network and config");
  const [model, config, humanModel] = await Promise.all([
    fetchBytes("./assets/model.txt.gz"),
    fetchBytes(humanMode ? "./assets/analysis.cfg" : "./assets/benchmark.cfg"),
    humanMode ? fetchBytes("./assets/human.bin.gz") : Promise.resolve(null),
  ]);
  module.FS.mkdir("/katago");
  module.FS.writeFile("/katago/model.txt.gz", model);
  module.FS.writeFile(humanMode ? "/katago/analysis.cfg" : "/katago/benchmark.cfg", config);
  if (humanModel) module.FS.writeFile("/katago/human.bin.gz", humanModel);

  const totalBytes = model.byteLength + (humanModel?.byteLength || 0);
  appendLog(`Models ready: ${(totalBytes / 1024 / 1024).toFixed(2)} MiB`, "success");
  setStatus("READY", humanMode ? "9x9 HumanSL policy" : "9x9 / 400 visits");
  runButton.textContent = humanMode ? "Run HumanSL Check" : "Run Benchmark";
  runButton.disabled = false;
  clearButton.disabled = false;
  saveButton.disabled = false;
}

function runBenchmark() {
  if (running) return;
  running = true;
  runButton.disabled = true;
  resultRow.hidden = true;
  setStatus("RUNNING", "Benchmark in progress");
  appendLog(humanMode ? "Starting HumanSL check..." : "Starting KataGo benchmark...", "success");

  const args = humanMode ? [
    "analysis",
    "-model", "/katago/model.txt.gz",
    "-human-model", "/katago/human.bin.gz",
    "-config", "/katago/analysis.cfg",
  ] : [
    "benchmark",
    "-model", "/katago/model.txt.gz",
    "-config", "/katago/benchmark.cfg",
    "-v", "400",
    "-t", "1",
    "-n", "1",
    "-boardsize", "9",
    "-fixed-batch-size", "1",
  ];
  module.callMain(args);
}

runButton.addEventListener("click", runBenchmark);
clearButton.addEventListener("click", () => {
  logLines = [];
  logOutput.replaceChildren();
});
saveButton.addEventListener("click", () => {
  const url = URL.createObjectURL(new Blob([logLines.join("\n")], { type: "text/plain" }));
  const link = document.createElement("a");
  link.href = url;
  link.download = "katago-browser-benchmark.txt";
  link.click();
  URL.revokeObjectURL(url);
});

initialize().catch((error) => {
  appendLog(error.stack || error.message, "error");
  setStatus("ERROR", error.message);
});
