# Activer les APIs nécessaires
resource "google_project_service" "ressource_manager" {
    service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "ressource_usage" {
    service = "serviceusage.googleapis.com"
    depends_on = [ google_project_service.ressource_manager ]
}

resource "google_project_service" "artifact" {
    service = "artifactregistry.googleapis.com"
    depends_on = [ google_project_service.ressource_manager ]
}

resource "google_project_service" "sql" {
  service = "sqladmin.googleapis.com"
  depends_on = [ google_project_service.ressource_manager ]
}

resource "google_project_service" "cloud_build" {
  service = "cloudbuild.googleapis.com"
  depends_on = [ google_project_service.ressource_manager ]
}

# Créer le repository Artifact Registry
resource "google_artifact_registry_repository" "my-repo" {
  location      = "us-central1"
  repository_id = "website-tools"
  description   = "Exemple de repo Docker"
  format        = "DOCKER"
  depends_on = [ google_project_service.artifact ]
}

# SQL Database
resource "google_sql_database" "database" {
  name     = "wordpress"
  instance = "main-instance"
}

# SQL User
resource "google_sql_user" "wordpress" {
   name     = "wordpress"
   instance = "main-instance"
   password = "ilovedevops"
}

data "google_iam_policy" "noauth" {
   binding {
      role = "roles/run.invoker"
      members = [
         "allUsers",
      ]
   }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
   location    = google_cloud_run_service.default.location # remplacer par le nom de votre ressource
   project     = google_cloud_run_service.default.project # remplacer par le nom de votre ressource
   service     = google_cloud_run_service.default.name # remplacer par le nom de votre ressource

   policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_service" "default" {
name     = "serveur-wordpress"
location = "us-central1"

template {
   spec {
      containers {
        ports {
          container_port = 80
        }
      image = "us-central1-docker.pkg.dev/devops-tp-449217/website-tools/image-wordpress:0.1"
      }
   }
}

traffic {
   percent         = 100
   latest_revision = true
}
}