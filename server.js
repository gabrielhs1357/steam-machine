const cors = require('cors');
const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

app.post('/suspend', (req, res) => {
    console.log('Recebido pedido de suspensão via API...');

    // Ctrl + Shift + 4 está mapeado no AHK para suspender o PC
    // Para enviar isso via WScript.Shell:
    // ^ = Ctrl
    // + = Shift
    const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+4')"`;

    exec(psCommand, (error, stdout, stderr) => {
        if (error) {
            console.error(`Erro ao executar comando: ${error.message}`);
            return res.status(500).json({ error: 'Erro ao enviar atalho de suspensão', details: error.message });
        }
        
        console.log('Atalho Ctrl+Shift+4 enviado com sucesso.');
        res.json({ message: 'Atalho de suspensão enviado', status: 'success' });
    });
});

app.get('/health-check', (req, res) => {
    console.log('Health check recebido...');
    res.json({ status: 'ok' });
});

app.get('/machine-mode', (req, res) => {
    console.log('Recebido pedido de machine-mode via API...');

    const iniPath = path.join(__dirname, 'src', 'scripts', 'machine_state.ini');
    const modeMap = { Desktop: 'Desktop', Console: 'Console' };
    let mode = 'Unknown';

    try {
        const content = fs.readFileSync(iniPath, 'utf8');
        const match = content.match(/Mode\s*=\s*(\S+)/);
        if (match) {
            mode = modeMap[match[1].trim()] ?? 'Unknown';
        }
    } catch (err) {
        console.error(`Erro ao ler machine_state.ini: ${err.message}`);
    }

    console.log(`Machine mode atual: ${mode}`);
    res.json({ mode });
});

app.post('/toggle-machine-mode', (req, res) => {
    console.log('Recebido pedido de toggle-machine-mode via API...');

    // O script AutoHotkey foi atualizado para escutar por Ctrl + Shift + 1
    // Para enviar isso via WScript.Shell:
    // ^ = Ctrl
    // + = Shift
    const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+1')"`;

    exec(psCommand, (error, stdout, stderr) => {
        if (error) {
            console.error(`Erro ao executar toggle-machine-mode: ${error.message}`);
            return res.status(500).json({ error: 'Erro ao enviar atalho Ctrl+Shift+1', details: error.message });
        }
        
        console.log('Atalho Ctrl+Shift+1 enviado com sucesso.');
        res.json({ message: 'Machine mode alternado via atalho', status: 'success' });
    });
});

app.post('/shutdown', (req, res) => {
    console.log('Recebido pedido de shutdown via API...');

    // Ctrl + Shift + 2 está mapeado no AHK para Shutdown(1)
    const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+2')"`;

    exec(psCommand, (error) => {
        if (error) {
            console.error(`Erro ao executar shutdown: ${error.message}`);
            return res.status(500).json({ error: 'Erro ao enviar atalho de shutdown', details: error.message });
        }

        console.log('Atalho Ctrl+Shift+2 enviado com sucesso.');
        res.json({ message: 'Shutdown iniciado via atalho', status: 'success' });
    });
});

app.post('/reboot', (req, res) => {
    console.log('Recebido pedido de reboot via API...');

    // Ctrl + Shift + 3 está mapeado no AHK para Shutdown(2)
    const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^+3')"`;

    exec(psCommand, (error) => {
        if (error) {
            console.error(`Erro ao executar reboot: ${error.message}`);
            return res.status(500).json({ error: 'Erro ao enviar atalho de reboot', details: error.message });
        }

        console.log('Atalho Ctrl+Shift+3 enviado com sucesso.');
        res.json({ message: 'Reboot iniciado via atalho', status: 'success' });
    });
});

app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
    console.log(`Rota disponível: POST http://localhost:${PORT}/suspend`);
    console.log(`Rota disponível: GET http://localhost:${PORT}/health-check`);
    console.log(`Rota disponível: GET http://localhost:${PORT}/machine-mode`);
    console.log(`Rota disponível: POST http://localhost:${PORT}/toggle-machine-mode`);
    console.log(`Rota disponível: POST http://localhost:${PORT}/shutdown`);
    console.log(`Rota disponível: POST http://localhost:${PORT}/reboot`);
});
