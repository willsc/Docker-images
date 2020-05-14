provider "google" {
credentials = "${file("/Users/cwills/Downloads/gcp-jenkins-project-c6215cf91324.json")}"
project = "gcp-jenkins-project"
region = "europe-west2"
}
