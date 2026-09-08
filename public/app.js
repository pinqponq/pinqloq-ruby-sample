const buttons = document.querySelectorAll("#status-buttons button");
const output = document.getElementById("output");
const runState = document.getElementById("run-state");

buttons.forEach(button => {
  button.addEventListener("click", async () => {
    const status = button.dataset.status;
    const startedAt = performance.now();
    const response = await fetch(`/demo/http/${status}`);
    const durationMs = Math.round(performance.now() - startedAt);
    const body = await response.json().catch(() => ({}));

    output.textContent = JSON.stringify(
      { requestedStatus: status, receivedStatus: response.status, durationMs, body },
      null,
      2
    );

    runState.textContent = `${response.status}`;
  });
});
