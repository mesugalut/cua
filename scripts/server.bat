@echo off

cd "%~dp0\..\libs\computer-server"

if not exist venv (
    python -m virtualenv venv
    call venv\Scripts\activate
    python -m pip install -e .
) else (
    call venv\Scripts\activate
)

python "%~dp0\server.py"
