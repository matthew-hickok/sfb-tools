
# pylint: disable=C0103
import urllib.request
from python_kemptech_api import LoadMaster, Template, VirtualService, Certificate

# connection parameters
LoadMaster_IP = '10.0.3.72' # Your LoadMaster’s administrative IP
LoadMaster_User = 'bal' # Your LoadMaster’s Login User
LoadMaster_Password = 'my_pass' # Your LoadMaster’s User’s Password
LoadMaster_Port = '443' # By default this is 443.

# build the LoadMaster object
lm = LoadMaster(LoadMaster_IP, LoadMaster_User, LoadMaster_Password, LoadMaster_Port)

# templates to use
vs_web_services_template = 'Skype Front End Reverse Proxy'
vs_owa_template = 'Skype Office Web App Servers'

template_url = 'https://kemptechnologies.com/files/assets/templates/SfB_2015.tmpl'

# front end servers
fe_servers = ('10.0.3.202', '10.0.3.203', '10.0.3.204')
# OWA/OOS servers
owa_servers = ('10.0.3.220')

# internal web services VIP
int_web_ip = '10.0.3.88'
# internal mobility VIP
int_mob_ip = '10.0.3.89'
# internal OWA VIP
int_owa_ip = '10.0.3.90'
# external web services VIP
ext_web_ip = '10.0.4.11'
# external OWA VIP
ext_owa_ip = '10.0.4.12'

# check for the SFB template, upload it if it's not there
ws_temp = lm.get_template(vs_web_services_template)
owa_temp = lm.get_template(vs_owa_template)
if (ws_temp is None) or (owa_temp is None):
    print('Missing a necessary template -- attempting to add it')
    urllib.request.urlretrieve(template_url, 'sfb.tmpl')
    lm.upload_template('sfb.tmpl')
else:
    print('Required templates are already installed')

# build the virtual Services using the appropriate template
lm.apply_template(int_web_ip, 80, 'tcp', vs_web_services_template, 'Internal Web Services')
lm.apply_template(ext_web_ip, 80, 'tcp', vs_web_services_template, 'External Web Services')
lm.apply_template(int_mob_ip, 443, 'tcp', vs_web_services_template, 'Internal Mobility')
lm.apply_template(int_owa_ip, 443, 'tcp', vs_owa_template, 'Internal OWA')
lm.apply_template(ext_owa_ip, 443, 'tcp', vs_owa_template, 'External OWA')


# store each virtual service in order to add real servers to each
int_web_vs_http = lm.get_virtual_service(address=int_web_ip, port='80', protocol='tcp')
int_web_vs_https = lm.get_virtual_service(address=int_web_ip, port='443', protocol='tcp')
ext_web_vs_http = lm.get_virtual_service(address=ext_web_ip, port='80', protocol='tcp')
ext_web_vs_https = lm.get_virtual_service(address=ext_web_ip, port='443', protocol='tcp')
int_mob_vs = lm.get_virtual_service(address=int_mob_ip, port='443', protocol='tcp')
int_owa_vs = lm.get_virtual_service(address=int_owa_ip, port='443', protocol='tcp')
ext_owa_vs = lm.get_virtual_service(address=ext_owa_ip, port='443', protocol='tcp')

# add the fe real servers to each appropriate virtual service
for item in fe_servers:
    int_web_rs_http = int_web_vs_http.create_real_server(item, port=80)
    int_web_rs_http.save()
    int_web_rs_https = int_web_vs_https.create_real_server(item, port=443)
    int_web_rs_https.save()
    ext_web_rs_http = ext_web_vs_http.create_real_server(item, port=8080)
    ext_web_rs_http.save()
    ext_web_rs_https = ext_web_vs_https.create_real_server(item, port=4443)
    ext_web_rs_https.save()
    int_mob_rs = int_mob_vs.create_real_server(item, port=4443)
    int_mob_rs.save()

# add the owa real servers to each appropriate virtual service
for item in owa_servers:
    int_owa_rs = int_owa_vs.create_real_server(item, port=443)
    int_owa_rs.save()
    ext_owa_rs = ext_owa_vs.create_real_server(item, port=443)
    ext_owa_rs.save()

