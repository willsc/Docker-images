### To Provision FireWall rule ###

resource "google_compute_firewall" "www" {
  name = "tf-www-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["8080", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}


### To provision Jenkins Master ###

resource "google_compute_instance" "jenkins-master-1" {
  name = "jenkins-master-1"
  machine_type = "f1-micro"
  zone = "europe-west2-a"
  tags = ["jenkins"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  metadata_startup_script = <<SCRIPT
apt install -y update
apt install -y docker.io
systemctl enable docker
systemctl start docker
docker pull jenkins
docker run -d -p 8080:8080 -p 50000:50000 --name master-1 docker pull willsgft/jenkins-master 
wget https://raw.githubusercontent.com/eficode/wait-for/master/wait-for -P /tmp
chmod +x /tmp/wait-for
/bin/sh /tmp/wait-for localhost:8080 -t 90
sleep 90
i=`hostname --ip-address`
f=`docker exec -i master-1 bash -c 'java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -remoting groovy /tmp/findkey --username admin --password admin'`
echo $f > /tmp/checkf
curl -k -H "Content-Type: application/json" -X POST -d '{"ip":"$i"}{"secret":"$f"} https://meeiot.org/put/58e6b7371ffe6c91c34560f0400a8f45212f370a0f863dee7ebf4a/jenkins
SCRIPT

  metadata =  {
    sshKeys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

output "public_ip_master" {
  value = ["${google_compute_instance.jenkins-master-1.*.network_interface.0.access_config.0.nat_ip}"]
}

### To provision Jenkins Slave ###
resource "google_compute_instance" "jenkins-slave-1" {
  name = "jenkins-slave-1"
  machine_type = "f1-micro"
  zone = "europe-west2-a"
  tags = ["jenkins"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  metadata_startup_script = <<SCRIPT
apt install -y update
apt install -y docker.io
systemctl enable docker
systemctl start docker
docker pull jenkinsci/jnlp-slave
sleep 120

curl  https://meeiot.org/get/58e6b7371ffe6c91c34560f0400a8f45212f370a0f863dee7ebf4a/jenkins >> /tmp/jenkins.out
cat /tmp/jenkins.out |grep -E -o "([0-9]{1,3}[.]){3}[0-9]{1,3}" > /tmp/ip.address
cat /tmp/jenkins.out |cut -d':' -f 3 | sed 's/"}//g' |sed 's/"//g'  > /tmp/secret
ipaddress=`cat /tmp/ip.address`
secret=`cat /tmp/secret`
docker run -d --name jenkins-slave1 jenkinsci/jnlp-slave -url http://$ipaddress:8080 $secret slave-1
SCRIPT

  metadata = {
    sshKeys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

output "public_ip_slave" {
  value = ["${google_compute_instance.jenkins-slave-1.*.network_interface.0.access_config.0.nat_ip}"]
}
