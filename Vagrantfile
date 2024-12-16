Vagrant.configure("2") do |config|


 # Base de Datos
  config.vm.define "bbdddfelipe" do |db|
    db.vm.box = "ubuntu/jammy64"
    db.vm.network "private_network", ip: "192.168.53.6"
    db.vm.provision "shell", path: "BBDDfelipe.sh"
  end
# Servidor NFS y PHP-FPM
  config.vm.define "nfssfelipe" do |nfs|
    nfs.vm.box = "ubuntu/jammy64"
    nfs.vm.network "private_network", ip: "192.168.53.5"
    nfs.vm.provision "shell", path: "nfsfelipe.sh"
  end


# Servidor Web 1
  config.vm.define "serverweb1felipe" do |web1|
    web1.vm.box = "ubuntu/jammy64"
    web1.vm.network "private_network", ip: "192.168.53.3"
    web1.vm.provision "shell", path: "serverwebfelipe.sh"
  end

  # Servidor Web 2
  config.vm.define "serverweb2felipe" do |web2|
    web2.vm.box = "ubuntu/jammy64"
    web2.vm.network "private_network", ip: "192.168.53.4"
    web2.vm.provision "shell", path: "serverwebfelipe.sh"
  end

  # Balanceador de Carga
  config.vm.define "balanceadorfelipe" do |balanceador|
    balanceador.vm.box = "ubuntu/jammy64"
    balanceador.vm.network "public_network", bridge: "enp0s3"
    balanceador.vm.network "private_network", ip: "192.168.53.2"
    balanceador.vm.network "forwarded_port", guest: 80, host: 8080
    balanceador.vm.provision "shell", path: "balanceadorfelipe.sh"
  end


  

  

 
end
