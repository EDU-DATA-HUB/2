Food Order — offline-kit (Windows)

prereqs\   (install by hand before setup — see Full_Guide.md)
  wsl.x64.msi
  DockerDesktopInstaller.zip

Zips expanded into ..\.runtime\ by setup.cmd:
  jdk-8.zip jdk-11.zip jdk-17.zip
  maven.zip
  m2.zip
  node.zip
  docker-images.zip
  app.zip

maven.zip + m2.zip enable offline build.cmd (mvn -o, no network).

Rebuild with: pack-offline-kit.cmd
