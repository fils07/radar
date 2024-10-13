RADAR is a tool to do reconnaissance which is the first and the one of most important steps of red teaming operation : bug bounty or penetration testing. The tool use sublist3r for subdomains enumeration and scan each subdomain to have open ports and version of service running on. 
The tool is fit to help you respect wanted scope, users can choose subdomains to scan or not.

Command to use radar :
chmod +x recon.sh
./recon.sh -t test_in.txt -o rapport.txt
-t is targets to enumerate and scan
-o the output file in which results will be write
