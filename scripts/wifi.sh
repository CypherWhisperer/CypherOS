#!/bin/bash

nmcli dev wifi connect "Cypher" password 'cyph3r@4796' ;
nmcli con mod "Cypher" ipv4.dns "1.1.1.1,8.8.8.8" ;
nmcli con mod "Cypher" ipv4.ignore-auto-dns yes  ;
sudo systemctl restart NetworkManager ;
