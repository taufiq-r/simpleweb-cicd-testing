job "postgres" {
  datacenters = ["dc1"]
  type        = "service"
  priority    = 100

  group "postgres" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:17"
        port_map {
          db = 5432
        }
        volumes = [
          "/data/postgres:/var/lib/postgresql/data"
        ]
      }

      env {
        POSTGRES_DB       = "appdb"
        POSTGRES_USER     = "app"
        POSTGRES_PASSWORD = "changeme"
      }

      resources {
        cpu    = 1000
        memory = 512
      }

      service {
        name = "postgres"
        port = "db"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
