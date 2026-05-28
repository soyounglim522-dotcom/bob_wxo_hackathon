# Installing the `orchestrate` CLI

`ibm-watsonx-orchestrate` requires **Python 3.11, 3.12, or 3.13**. The package
metadata pins `<3.14,>=3.11` and pip enforces it — `pip install` on Python 3.14
(the current macOS Homebrew default) will fail with:

```
ERROR: Package 'ibm-watsonx-orchestrate' requires a different Python:
3.14.x not in '<3.14,>=3.11'
```

So the install has two steps: **(1) get a compatible Python, (2) `pip install`
into a venv built from that Python**.

## macOS

```bash
# 1. Install Python 3.12 (skip if you already have 3.11–3.13)
brew install python@3.12

# 2. Create a venv in your project directory and activate it
python3.12 -m venv .venv
source .venv/bin/activate

# 3. Install the ADK
pip install ibm-watsonx-orchestrate

# 4. Verify
orchestrate --version
```

You should see `ADK Version: 2.x.x ...`.

## Linux

```bash
# 1. Install Python 3.12 — Debian/Ubuntu
sudo apt update
sudo apt install python3.12 python3.12-venv

# (Fedora: sudo dnf install python3.12  — Arch: pacman -S python — etc.)

# 2-4. Same as macOS
python3.12 -m venv .venv
source .venv/bin/activate
pip install ibm-watsonx-orchestrate
orchestrate --version
```

## Windows

```powershell
# 1. Install Python 3.12 from https://www.python.org/downloads/
# (Make sure "Add Python to PATH" is checked during install.)

# 2. Create + activate venv
py -3.12 -m venv .venv
.venv\Scripts\activate

# 3. Install + verify
pip install ibm-watsonx-orchestrate
orchestrate --version
```

## Per-project dependencies

Once your venv is set up, install the rest of the deps:

```bash
pip install -r requirements.txt
```

`requirements.txt` lives in this same `starter/` directory.

## Important: `orchestrate` is only on PATH while the venv is active

Every new terminal session you'll need to `source .venv/bin/activate`
(macOS/Linux) or `.venv\Scripts\activate` (Windows) before running
`orchestrate` commands. If you forget, you'll get `orchestrate: command not
found` even though it's installed.

## Verifying the install

```bash
orchestrate --version
# → ADK Version: 2.x.x ...

python -c "import ibm_watsonx_orchestrate; print(ibm_watsonx_orchestrate.__version__)"
# → 2.x.x (same version)
```

## Optional: `uv` instead of pip

If you happen to already have [`uv`](https://docs.astral.sh/uv/) installed, you
can skip the Python-version step entirely — uv ignores `requires-python` and
installs on any Python:

```bash
uv tool install ibm-watsonx-orchestrate    # installs `orchestrate` globally
orchestrate --version
```

This isn't required and isn't worth installing uv just for this — pip works
fine. But it's noted here for completeness.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `pip install` fails with `requires a different Python: 3.14.x not in <3.14,>=3.11` | Your default Python is 3.14. Install 3.12 (`brew install python@3.12`) and re-create the venv with `python3.12 -m venv .venv`. |
| `orchestrate: command not found` | Venv isn't activated. `source .venv/bin/activate` (macOS/Linux) or `.venv\Scripts\activate` (Windows). |
| `python3.12: command not found` after `brew install python@3.12` | Homebrew may not have linked it. `brew link python@3.12 --force` or use the full path: `/opt/homebrew/opt/python@3.12/bin/python3.12 -m venv .venv`. |
| `ImportError: cannot import name 'X' from 'ibm_watsonx_orchestrate.agent_builder.tools'` after a working install | Version skew — the skill templates target `ibm-watsonx-orchestrate >= 2.0`. Upgrade: `pip install -U ibm-watsonx-orchestrate`. |
| Lots of "Could not find a version" errors during `pip install` | Older pip can't resolve. Upgrade: `python -m pip install --upgrade pip`, then retry. |
