# Offline notes

Use the root helpers documented in **[Full_Guide.md](../../Full_Guide.md)**.

All offline payloads live under **`offline-kit\*.zip`** (JDKs, Node, Docker Desktop installer, infra images, app).  
`setup.cmd` expands them into `.runtime\`. Do **not** keep `01-docker-images.tar` or similar archives at the project root.

Rebuild the kit on an online machine:

```bat
pack-offline-kit.cmd
```
