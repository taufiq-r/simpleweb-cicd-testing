job "frontend" {
  datacenters = ["dc1"]
  group "frontend" {
    task "web" {
      driver = "docker"
      config {
        image = "ghcr.io/{{env "IMAGE_OWNER"}}/{{env "REPO_NAME"}}-frontend:latest"
        port_map { http = 80 }
      }
      resources { cpu = 300, memory = 256 }
    }
  }
}
