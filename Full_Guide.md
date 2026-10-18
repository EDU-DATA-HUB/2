# Full Guide

## Contents

1. [Set up](#1-set-up)
2. [Start](#2-start)
  2.1. [Login](#21-login)
3. [Stop](#3-stop)
4. [Build](#4-build)

---

## 1. Set up

### 1.1 Docker installation

Open **Command Prompt as Administrator** and enable **Windows features**:

```bat
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

```bat
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

Then install by hand from `offline-kit\prereqs\`:

1. Run `wsl.x64.msi` and install it.
2. Unzip `DockerDesktopInstaller.zip`.
3. Run `DockerDesktopInstaller.exe` and complete the install (WSL 2 backend if asked).
4. Reboot PC if asked.
5. Start Docker Desktop and wait until the engine is running.

### 1.2 Unpack packages

```bat
setup.cmd
```

---



## 2. Start

1. Start Docker Desktop.
2. Run `start.cmd` in the project folder.
3. Wait until it finishes (first boot can take a few minutes — normal).
4. Open [http://localhost:4200](http://localhost:4200)

Do not run `start.cmd` twice. Run `stop.cmd` first if you want to restart.

### 2.1 Login


|          |                                                |
| -------- | ---------------------------------------------- |
| URL      | [http://localhost:4200](http://localhost:4200) |
| Username | user                                           |
| Password | user123                                        |


Admin: `admin` / `admin123`


| What        | URL                                            |
| ----------- | ---------------------------------------------- |
| Website     | [http://localhost:4200](http://localhost:4200) |
| API gateway | [http://localhost:9000](http://localhost:9000) |
| Eureka      | [http://localhost:8761](http://localhost:8761) |


---



## 3. Stop

```bat
stop.cmd
```

If a port is still in use:

```bat
netstat -ano | findstr ":9000"
taskkill /PID <pid> /F
```

---



## 4. Build

Build is **fully offline** after `setup.cmd` (bundled JDK, Maven, and local `m2` repo — no downloads).

Stop the services before building if they are running (`stop.cmd`).

Open **Command Prompt** in the project folder and run:

```bat
build.cmd
```

Default Java is **8**. To use 11 or 17 run Command Prompt in this folder and run:

```bat
set FOOD_JAVA_VERSION=11
build.cmd
start.cmd
```

(`FOOD_JAVA_VERSION` may be `8`, `11`, or `17`.)

---

