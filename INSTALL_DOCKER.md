# Running the ASE RISC-V / gem5 simulator with Docker

This is the easiest way to get a working environment on **macOS (Intel or Apple Silicon),
Windows 10/11 and Linux**. Everything (RISC-V GNU toolchain, gem5, Python, ASE Studio's
backend) lives inside one Docker image, so nothing has to be compiled on your computer and
nothing is installed on your system. You edit programs on your own machine; Docker runs them.

You can use either:
- **ASE Studio** (a web page you open in your browser) to write programs and see the pipeline, or
- the **command line** (`./sim.sh`) to simulate a program and read `stats.txt`.

---

## 1. Install the prerequisites (once)

| System | What to install |
|---|---|
| **macOS** | [Docker Desktop](https://www.docker.com/products/docker-desktop/) and Git (`xcode-select --install`). |
| **Windows 10/11** | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (use the WSL 2 backend) and [Git for Windows](https://git-scm.com/download/win), which includes *Git Bash*. |
| **Linux** | Docker Engine (<https://docs.docker.com/engine/install/>) and Git. Add yourself to the `docker` group: `sudo usermod -aG docker $USER`, then log out and in. |

Start Docker Desktop and wait until it says it is running.
**Recommended Docker settings** (Docker Desktop → Settings → Resources): at least **4 GB RAM**
to *use* the image, and **8 GB RAM / 4 CPUs** if you will *build* the image yourself (section 3b).

## 2. Download the repository

Open a terminal (macOS/Linux: *Terminal*; Windows: **Git Bash**) and run:

```bash
git clone --branch main --recurse-submodules https://github.com/cad-polito-it/ase_riscv_gem5_sim.git
cd ase_riscv_gem5_sim
```

The `--recurse-submodules` option also downloads ASE Studio. If you forgot it, run
`git submodule update --init --recursive`.

## 3. Get the Docker image

### 3a. Download a ready-made image (fast, recommended)

If your teacher gave you an image name (for example `ghcr.io/<owner>/ase-riscv-gem5:latest`),
tell the scripts to use it, then pull it:

```bash
export ASE_IMAGE=ghcr.io/<owner>/ase-riscv-gem5:latest      # Windows PowerShell: $env:ASE_IMAGE="..."
docker pull "$ASE_IMAGE"
```

The correct build for your computer (Intel/AMD or Apple Silicon) is picked automatically.
You need to set `ASE_IMAGE` in every new terminal, or the scripts will build locally (3b).

### 3b. Build it yourself (no image available, takes 1-3 hours, once)

Nothing to do: the first time you run `./sim.sh` or `./studio.sh` and no image exists, the
scripts build it from `docker/Dockerfile`. You can also do it explicitly:

```bash
docker build -t ase-riscv-gem5:local -f docker/Dockerfile .
```

If the build fails with *Killed* or *out of memory*, give Docker more RAM, or lower the load:
`docker build --build-arg GEM5_JOBS=1 --build-arg TOOLCHAIN_JOBS=2 -t ase-riscv-gem5:local -f docker/Dockerfile .`

## 4. Use ASE Studio

```bash
./studio.sh
```

Your browser opens **http://127.0.0.1:8765**. Click **New**, type a project name
(for example `program_1`), click **Create**, then write your assembly between `_start:` and
`End:` (the template lines around it are locked on purpose). Your programs are saved in the
`programs/` folder of the repository, on your computer.

Stop it with `./studio.sh stop`. Run `./studio.sh` again any time you restart your computer
(Docker Desktop must be running).

## 5. Simulate from the command line (without ASE Studio)

```bash
./sim.sh example                          # builds programs/example and simulates it
./sim.sh program_1                        # your own project
./sim.sh example -- --l1d_size 8kB        # extra gem5 options after --
L1D=8kB L1I=8kB CACHELINE=32 ./sim.sh example    # cache settings (defaults 4kB / 4kB / 16)
```

Results are written to `results/<name>/`: `stats.txt` (cycles, instructions, ...), the
`<name>.elf` executable and the `<name>.dump` disassembly.

## Windows PowerShell (without Git Bash)

If you prefer PowerShell, use Docker Compose from the repository folder instead of the scripts:

```powershell
docker compose run --rm sim ase-sim example     # simulate programs/example
docker compose up studio                         # then open http://127.0.0.1:8765  (Ctrl+C to stop)
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `Docker is installed but not running` | Start Docker Desktop and wait for it to finish starting. |
| `ase_studio is empty` | `git submodule update --init --recursive` |
| Port 8765 already in use | `ASE_STUDIO_PORT=8800 ./studio.sh`, then open that port. |
| `docker: permission denied` (Linux) | `sudo usermod -aG docker $USER`, then log out and back in. |
| Image build is killed | Raise Docker's memory (Settings → Resources) or use the `--build-arg` options in 3b. |
| Windows: `./sim.sh` not found | Run it from **Git Bash** (not PowerShell/cmd), or use the Compose commands above. |
| Everything is slow on Apple Silicon | Use an `arm64` image (3a does this automatically). Do not force `--platform linux/amd64`. |
| Start over | `docker rm -f ase-studio; docker rmi ase-riscv-gem5:local` |

## For teachers: publishing the image

`.github/workflows/docker-image.yml` builds the image natively for **amd64 and arm64** on GitHub
and publishes it to `ghcr.io/<owner>/ase-riscv-gem5` (run it from the repository's *Actions*
tab, "docker-image" → *Run workflow*). After the first run, open the package on GitHub →
*Package settings* → set visibility to **Public** so students can pull without logging in.
Then hand students the `ASE_IMAGE=ghcr.io/<owner>/ase-riscv-gem5:latest` line from step 3a.
