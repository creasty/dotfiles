section "Installing vagrant boxes"
# subsection "CentOS 6.5 x86_64"
# vagrant box add centos65 https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box
# print_status $?

subsection "CentOS 7.0 x86_64"
vagrant box add centos70 https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box
print_status $?

section "Installing vagrant plugins"
vagrant plugin install sahara
print_status $?
