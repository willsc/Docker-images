provider "google" {
credentials = "${file("jenkins-project-276418-198bbe39de24.json")}"
project = "jenkins-project"
region = "europe-west2"
}
