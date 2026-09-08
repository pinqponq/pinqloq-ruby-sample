const output = document.getElementById("output");
const runState = document.getElementById("run-state");
const connection = document.getElementById("connection");
const configState = document.getElementById("config-state");
const httpCollection = document.getElementById("http-collection");
const manualCollection = document.getElementById("manual-collection");

async function loadConfig() {
  const response = await fetch("/api/config");
  const config = await response.json();

  connection.textContent = config.configured ? "Connected" : "Not configured";
  configState.textContent = config.configured ? "Configured on the server" : "Set PINQLOQ_SECRET_KEY to enable delivery";
  httpCollection.textContent = config.httpCollection || "—";
  manualCollection.textContent = config.manualCollection || "—";
}

async function report(promise) {
  const startedAt = performance.now();
  const response = await promise;
  const durationMs = Math.round(performance.now() - startedAt);
  const body = await response.json().catch(() => ({}));

  runState.textContent = `${response.status}`;
  output.textContent = JSON.stringify({ receivedStatus: response.status, durationMs, body }, null, 2);
}

document.querySelectorAll("#status-buttons button").forEach(button => {
  button.addEventListener("click", () => {
    report(fetch(`/demo/http/${button.dataset.status}`));
  });
});

document.getElementById("manual").addEventListener("click", () => {
  const level = document.getElementById("level").value;
  report(fetch(`/demo/manual/${level}`, { method: "POST" }));
});

document.querySelectorAll(".redaction-buttons button").forEach(button => {
  button.addEventListener("click", () => {
    const path = button.dataset.redaction === "endpoint" ? "/demo/redaction/endpoint" : "/demo/redaction/fields";

    report(
      fetch(path, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          password: "synthetic-pass-1234",
          taxNumber: "TX-99-12345"
        })
      })
    );
  });
});

loadConfig();
