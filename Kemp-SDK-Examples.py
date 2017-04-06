# -*- coding: UTF-8 -*-
# pylint: disable=C0103

from python_kemptech_api import LoadMaster, Template, VirtualService
LoadMaster_IP = "10.0.3.72" # Your LoadMaster’s administrative IP
LoadMaster_User = "bal" # Your LoadMaster’s Login User
LoadMaster_Password = "my_password!!!" # Your LoadMaster’s User’s Password
LoadMaster_Port = "443" # By default this is 443.

# Build the LoadMaster object
lm = LoadMaster(LoadMaster_IP, LoadMaster_User, LoadMaster_Password, LoadMaster_Port)

'''
# Get single virtual service
service = lm.get_virtual_service(address="10.0.3.84", port="80", protocol="tcp")
print(service)
'''

'''
# Get all virtual services
services = lm.get_virtual_services()
for item in services:
    print(item)
'''

'''
# Add a local user
lm.add_local_user("myNewUser",password="mypassword",radius=False)
'''

'''
# Create virtual service
service = lm.create_virtual_service("10.0.3.84", port=80, protocol="tcp")
service.save()
'''

'''
# Create real server
service = lm.get_virtual_service(address="10.0.3.84", port="80", protocol="tcp")
real_server = service.create_real_server("10.0.3.85", port=80)
real_server.save()
'''

'''
# Get Real Servers attached to a VS
service = lm.get_virtual_service(address="10.0.3.84", port="80", protocol="tcp")
rs = service.get_real_servers()
for server in rs:
    print(server)
'''

'''
# Reboot the load LoadMaster
 lm.reboot()
'''

'''
# Get a single template
lm.get_template("Skype Mediation HLB Only")
'''

'''
# Get all templates
templates = lm.get_templates()
for temps in templates:
    print(temps)
'''

'''
# Get interfaces
interfaces = lm.get_interfaces()
for inters in interfaces:
    print(inters)
'''

# Upload a template
# lm.upload_template(r'C:\Users\matt.MHICKOK\Downloads\Exchange2010Core.tmpl')
