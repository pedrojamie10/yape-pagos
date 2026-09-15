@echo off
title Yape Realtime Hub Server
cd /d "%~dp0\server"
echo ========================================================
echo   Iniciando Servidor Hub de Notificaciones Yape
echo ========================================================
node src/index.js
pause
