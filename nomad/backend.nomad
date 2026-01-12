job "backend" {
  datacenters = ["dc1"]
  group "backend" {
    task "api" {
      driver = "docker"
      config {
        image = "ghcr.io/{{env "IMAGE_OWNER"}}/{{env "REPO_NAME"}}-backend:latest"
        port_map { http = 3000 }
      }
      resources { cpu = 500, memory = 512 }
    }
  }
}
