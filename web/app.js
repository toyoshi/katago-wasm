import createKataGo from "./assets/katago.js";

const statusValue = document.querySelector("#status-value");
const progressValue = document.querySelector("#progress-value");
const resultRow = document.querySelector("#result-row");
const resultValue = document.querySelector("#result-value");
const runButton = document.querySelector("#btn-run");
const clearButton = document.querySelector("#btn-clear");
const saveButton = document.querySelector("#btn-save-log");
const logOutput = document.querySelector("#log-output");

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

  setStatus("LOADING", "WebAssembly module");
  module = await createKataGo({
    locateFile: (path) => `./assets/${path}`,
    print: (text) => appendLog(text),
    printErr: (text) => appendLog(text, "warn"),
    onExit: (code) => {
      running = false;
      runButton.disabled = true;
      setStatus(code === 0 ? "DONE" : "ERROR", `Exit code ${code}`);
    },
  });

  setStatus("LOADING", "Network and config");
  const [model, config] = await Promise.all([
    fetchBytes("./assets/model.txt.gz"),
    fetchBytes("./assets/benchmark.cfg"),
  ]);
  module.FS.mkdir("/katago");
  module.FS.writeFile("/katago/model.txt.gz", model);
  module.FS.writeFile("/katago/benchmark.cfg", config);

  appendLog(`Model ready: ${(model.byteLength / 1024 / 1024).toFixed(2)} MiB`, "success");
  setStatus("READY", "9x9 / 400 visits");
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
  appendLog("Starting KataGo benchmark...", "success");

  module.callMain([
    "benchmark",
    "-model", "/katago/model.txt.gz",
    "-config", "/katago/benchmark.cfg",
    "-v", "400",
    "-t", "1",
    "-n", "1",
    "-boardsize", "9",
    "-fixed-batch-size", "1",
  ]);
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
