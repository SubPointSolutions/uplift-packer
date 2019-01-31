# -*- mode: ruby -*-
# vi: set ft=ruby :

box_name       =  ENV['UPLF_VAGRANT_BOX_NAME']       || "uplift-local/ubuntu-trusty64" 
machine_folder =  ENV['UPLF_VBMANAGE_MACHINEFOLDER'] || nil

if !machine_folder.nil? 
    puts "custom MACHINEFOLDER: #{machine_folder}"
    system("vboxmanage setproperty machinefolder #{machine_folder}")
end

puts "Using box_name: #{box_name}"

uplift = VagrantPlugins::Uplift::Config()

unless Vagrant.has_plugin?("vagrant-reload")
  raise 'vagrant-reload plugin not installed!'
end

unless Vagrant.has_plugin?("vagrant-uplift")
  raise 'vagrant-uplift plugin not installed!'
end

Vagrant.configure("2") do |config|
  
  config.vm.define "empty", autostart: false do | vm_config |   
    vm_config.vm.box = box_name
    vm_config.vm.box_check_update = false

    config.vm.provision "shell", inline: "hostname"

    vm_config.vm.provider "virtualbox" do |v|
      v.gui  = false
      
      v.cpus    = 2
      v.memory  = 512

      v.linked_clone = false
    end
  end

  config.vm.define "dc", autostart: true do | vm_config |   
    
    vm_config.vm.box = box_name
    vm_config.vm.box_check_update = false

    vm_config.vm.provider "virtualbox" do |v|
      v.gui  = false
      
      v.cpus    = 2
      v.memory  = 512

      v.linked_clone = false
    end

  end  

  config.vm.define "client" do | vm_config |   
    
    vm_config.vm.box = box_name
    vm_config.vm.box_check_update = false

    vm_config.vm.provider "virtualbox" do |v|
      v.gui  = false
      
      v.cpus    = 2
      v.memory  = 512

      v.linked_clone = false
    end

  end  

end