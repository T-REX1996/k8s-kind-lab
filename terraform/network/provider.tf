# プロジェクトとリージョンは、変数で受け取る（実値は terraform.tfvars に書く。コミットしない）。
provider "google" {
  project = var.project_id
  region  = var.region
}
