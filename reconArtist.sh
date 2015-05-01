#! /bin/sh

# This script will perform recon tasks.  

# Use:  ./reconArtist.sh <targetDomain>
#  i.e.  ./reconArtist.sh testcompany.com

# Create and move to working directory
mkdir $1
cd $1

# Run theharvester to obtain email addresses and web servers from Google, Bing, etc

theharvester -d $1 -b all -l 500 -f $1.html && grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' $1.html |sort|uniq > IPsForTarget.txt

# Run fierce to locate subdomains

fierce -dns $1 -file fierceOutput.txt -suppress && grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' fierceOutput.txt |sort|uniq >> IPsForTarget.txt

# Cleanup IPsForTarget.txt file to make sure they are all uniq IPs
cat IPsForTarget.txt | sort | uniq > IPsForTarget-s.txt

# Run whois on domain
whois $1 > Whois.txt
while read ip;do whois $ip >> whoisIPs.txt;done <IPsForTarget-s.txt

# You get some email addresses, you get some email addresses, EVERYBODY GETS SOME EMAIL ADDRESSES!
grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,4\}' $1.html > emailAccounts.txt


