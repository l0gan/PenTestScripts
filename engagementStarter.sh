#! /bin/bash
# Use:  ./engagementStarter.sh <target ip/subnet> <customerDomainName> <interfaceIP>
# e.g.:  ./engagementStarter.sh 192.168.108.1/24 testco.com 192.168.108.5
#  InterfaceIP is used to start responder.  This is the IP address of your interface that will be used to respond to requests.
# you must have the following tools installed:
#   - nmap
#   - metasploit pro (if just metasploit, modify the msfpro to msfconsole and remove the --
#   - EyeWitness (obtain from https://github.com/ChrisTruncer/EyeWitness) located at /opt/EyeWitness
#   - sslscan
#   - snmpcheck
#   - responder
#   - nikto
#   - theharvester
#  Most of these tools come pre-installed in Kali


# create working folder
mkdir $2
cd $2

# Start responder for network
if [ -n "$3" ] 
then 
	xterm -e "responder -i $3 -I eth1 -wrf"& 
else 
	echo "not running responder" 
fi 

# Start nmap for network
nmap -sn $1 -oG discoveryScan.gnmap && cat discoveryScan.gnmap | awk '{print $2}' | grep -v Nmap > ActiveIPs.txt
nmap -sS -A -iL ActiveIPs.txt -oA FullscanTCP
nmap -sU --top-ports 20 -iL ActiveIPs.txt -oA FullscanUDP

# import results into metasploit pro
xterm -e "msfpro -- -x 'db_status;workspace;workspace -a $2;workspace $2;db_import FullscanTCP.xml;db_import FullscanUDP.xml;exit -y'"&

#create https list
python /opt/EyeWitness/EyeWitness.py -f FullscanTCP.xml --no-dns --createtargets HTTP-s_targets.txt
cat HTTP-s_targets.txt | grep https |sed 's/https:\/\///' > httpsTargets.txt

# run sslscan on ssl hosts
xterm -e "sslscan --targets=httpsTargets.txt > sslScanResults.txt"&

# run eyewitness to scrape http/s pages
xterm -e "python /opt/EyeWitness/EyeWitness.py -d $2 -f FullscanTCP.xml && iceweasel /opt/EyeWitness/$2/report.html"&

# run nikto on http/s pages
cat HTTP-s_targets.txt | sed 's/http:\/\///'|sed 's/https:\/\///' > http-sHosts.txt
while read targets; do xterm -e "nikto -h $targets >> niktoResults.txt";done <http-sHosts.txt&

# run snmpcheck on snmp hosts
cat FullscanUDP.gnmap | grep 161/open/ | awk '{print $2}' > snmpHosts.txt
while read h; do snmpcheck -t $h ;done <snmpHosts.txt

