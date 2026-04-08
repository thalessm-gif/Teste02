@echo off
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0importar-atletas-csv.ps1"
