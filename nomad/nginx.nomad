job "nginx" {
  datacenters = ["dc1"]
  type        = "service"

  group "nginx" {
    count = 1

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        port_map {
          http = 80
        }
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf:ro"
        ]
      }

      template {
        data = file("../nginx/nginx.conf")
        destination = "local/nginx.conf"
      }

      resources {
        cpu    = 300
        memory = 256
      }

      service {
        name = "nginx"
        port = "http"
        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
