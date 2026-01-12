job "pgbouncer" {
  datacenters = ["dc1"]
  type        = "service"

  group "pgbouncer" {
    count = 1

    task "pgbouncer" {
      driver = "docker"

      config {
        image = "edoburu/pgbouncer:latest"
        port_map {
          bouncer = 6432
        }
        volumes = [
          "local/pgbouncer.ini:/etc/pgbouncer/pgbouncer.ini:ro",
          "local/userlist.txt:/etc/pgbouncer/userlist.txt:ro"
        ]
      }

      template {
        data = <<EOH
[databases]
appdb = host={{ range service "postgres" }}{{ .Address }}{{ end }} port=5432 dbname=appdb

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 100
default_pool_size = 20
EOH
        destination = "local/pgbouncer.ini"
      }

      template {
        data = "\"app\" \"md5HASH_HERE\""
        destination = "local/userlist.txt"
      }

      resources {
        cpu    = 500
        memory = 256
      }

      service {
        name = "pgbouncer"
        port = "bouncer"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
