const cors = require("cors");
const express = require("express");
const { exec } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

app.post("/games/:appId/launch", (req, res) => {
	const { appId } = req.params;

	if (!appId || Number.isNaN(appId)) {
		return res
			.status(400)
			.json({ error: "Steam App ID inválido ou não fornecido na URL" });
	}

	console.log(
		`\n--- Solicitação de inicialização recebida para o jogo ID: ${appId} ---`,
	);

	// Comando nativo do Windows para disparar o protocolo da Steam e abrir o jogo
	const launchCommand = `start steam://rungameid/${appId}`;

	exec(launchCommand, (error) => {
		if (error) {
			console.error(
				`Erro ao tentar executar o jogo na Steam: ${error.message}`,
			);
			return res.status(500).json({
				error: "Falha ao executar o comando da Steam",
				details: error.message,
			});
		}

		console.log(
			`🚀 Comando 'start steam://rungameid/${appId}' enviado com sucesso para o Windows!`,
		);
		res.json({
			message: `Comando de inicialização enviado para o jogo ${appId}`,
			status: "success",
		});
	});
});

app.post("/suspend", (_req, res) => {
	console.log("Recebido pedido de suspensão via API...");

	// Ctrl + Shift + 4 está mapeado no AHK para suspender o PC
	// Para enviar isso via WScript.Shell:
	// ^ = Ctrl
	// + = Shift
	const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+4')"`;

	exec(psCommand, (error, _stdout, _stderr) => {
		if (error) {
			console.error(`Erro ao executar comando: ${error.message}`);
			return res.status(500).json({
				error: "Erro ao enviar atalho de suspensão",
				details: error.message,
			});
		}

		console.log("Atalho Ctrl+Shift+4 enviado com sucesso.");
		res.json({ message: "Atalho de suspensão enviado", status: "success" });
	});
});

app.get("/health-check", (_req, res) => {
	console.log("Health check recebido...");
	res.json({ status: "ok", mode: getCurrentMachineMode() });
});

app.get("/machine-mode", (_req, res) => {
	console.log("Recebido pedido de machine-mode via API...");

    const mode = getCurrentMachineMode();

	console.log(`Machine mode atual: ${mode}`);
	res.json({ mode });
});

function getCurrentMachineMode() {
    const iniPath = path.join(__dirname, "src", "scripts", "machine_state.ini");
    const modeMap = { Desktop: "Desktop", Console: "Console" };
    let mode = "Unknown";

    try {
		const content = fs.readFileSync(iniPath, "utf8");
		const match = content.match(/Mode\s*=\s*(\S+)/);
		if (match) {
			mode = modeMap[match[1].trim()] ?? "Unknown";
		}
	} catch (err) {
		console.error(`Erro ao ler machine_state.ini: ${err.message}`);
	}
    return mode;
}

app.post("/toggle-machine-mode", (_req, res) => {
	console.log("Recebido pedido de toggle-machine-mode via API...");

	// O script AutoHotkey foi atualizado para escutar por Ctrl + Shift + 1
	// Para enviar isso via WScript.Shell:
	// ^ = Ctrl
	// + = Shift
	const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+1')"`;

	exec(psCommand, (error, _stdout, _stderr) => {
		if (error) {
			console.error(`Erro ao executar toggle-machine-mode: ${error.message}`);
			return res.status(500).json({
				error: "Erro ao enviar atalho Ctrl+Shift+1",
				details: error.message,
			});
		}

		console.log("Atalho Ctrl+Shift+1 enviado com sucesso.");
		res.json({
			message: "Machine mode alternado via atalho",
			status: "success",
		});
	});
});

app.post("/shutdown", (_req, res) => {
	console.log("Recebido pedido de shutdown via API...");

	// Ctrl + Shift + 2 está mapeado no AHK para Shutdown(1)
	const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+2')"`;

	exec(psCommand, (error) => {
		if (error) {
			console.error(`Erro ao executar shutdown: ${error.message}`);
			return res.status(500).json({
				error: "Erro ao enviar atalho de shutdown",
				details: error.message,
			});
		}

		console.log("Atalho Ctrl+Shift+2 enviado com sucesso.");
		res.json({ message: "Shutdown iniciado via atalho", status: "success" });
	});
});

app.post("/nyrna", (_req, res) => {
	console.log(
		"Recebido pedido para suspender o processo com o Nyrna via API...",
	);

	// Adicionado -WindowStyle Hidden para evitar que o PowerShell crie interface gráfica
	const psCommand = `powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+5')"`;

	// A opção { windowsHide: true } é crucial: ela diz ao Node.js para ocultar a janela do subprocesso
	exec(psCommand, { windowsHide: true }, (error) => {
		if (error) {
			console.error(`Erro ao executar suspend: ${error.message}`);
			return res.status(500).json({
				error: "Erro ao enviar atalho de suspend",
				details: error.message,
			});
		}

		console.log("Atalho Ctrl+Shift+5 enviado com sucesso.");

		res.json({ message: "Nyrna chamado via atalho", status: "success" });
	});
});

app.post("/reboot", (_req, res) => {
	console.log("Recebido pedido de reboot via API...");

	// Ctrl + Shift + 3 está mapeado no AHK para Shutdown(2)
	const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+3')"`;

	exec(psCommand, (error) => {
		if (error) {
			console.error(`Erro ao executar reboot: ${error.message}`);
			return res.status(500).json({
				error: "Erro ao enviar atalho de reboot",
				details: error.message,
			});
		}

		console.log("Atalho Ctrl+Shift+3 enviado com sucesso.");
		res.json({ message: "Reboot iniciado via atalho", status: "success" });
	});
});

app.listen(PORT, () => {
	console.log(`Servidor rodando na porta ${PORT}`);
	console.log(`Rota disponível: POST http://localhost:${PORT}/suspend`);
	console.log(`Rota disponível: GET http://localhost:${PORT}/health-check`);
	console.log(`Rota disponível: GET http://localhost:${PORT}/machine-mode`);
	console.log(
		`Rota disponível: POST http://localhost:${PORT}/toggle-machine-mode`,
	);
	console.log(`Rota disponível: POST http://localhost:${PORT}/shutdown`);
	console.log(`Rota disponível: POST http://localhost:${PORT}/reboot`);
    console.log(`Rota disponível: POST http://localhost:${PORT}/nyrna`);
    console.log(`Rota disponível: POST http://localhost:${PORT}/games/:appId/launch`);
});
