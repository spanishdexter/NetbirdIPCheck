# NetBirdIPCheck
For auto-connecting and disconnecting your NetBird client based on public IP addresses on a posture check on your Netbird server.

my website: https://www.jdsoft.rocks/
my github repos: https://github.com/spanishdexter

# LICENSE
Modify, brand and use however you see fit as long as it's not illegal or immoral. Uses an MIT License. See LICENSE.TXT.

# DISCLAIMER 

Use this software at your own risk. I take no responsibility if you deploy this and damage occurs, be it a business environment or home environment. You as the IT professional are responsible for testing and making sure this script is compatible with your environment and configuration.

# Description
These scripts will allow a client for Netbird, an open source mesh-based VPN suite, on your Windows device to connect or disconnect based on it's outbound internet IP address.

This can allow for scenarios where your on-premise, on your trusted network and DO NOT want to have your VPN client running to avoid routing issues, etc. Netbird does allow you to use posture checks for internal LAN IP's to deal with this, but not public IPs. That is where this solution helps.

The EXE files part of this repo are self-extracting CAB archives created with the built in Windows tool IExpress.exe. The scripts are executed after being extracted temporarily in the %temp% folder in Windows. The files will be deleted when the scripts are closed.

The source SED files for these EXEs have been included as part of the source code.


# Requirements

-A Netbird server

-Peer Network Range posture check on your Netbird server named EXACTLY as this: "Block Public IPs from VPN", normally Peer Network Range is used for the LAN IPs to blacklist, but instead you will use it for public IP's with /32 CIDR. Example 0.0.0.0/32. Posture check will be assigned to a group the computer is a member of.

-Process posture check called "NetbirdPublicIPCheckerPass.exe - Connect if running" that checks for NetbirdPublicIPCheckerPass.exe at it's path "C:\NetBirdIPCheck\NetbirdPublicIPCheckerPass.exe". Posture check will be assigned to a group the computer is a member of.

-The ability to work in the windows registry on the endpoint client devices running the VPN client. You will need to define the appropriate settings in order for this script to work properly. As such you'll need administrative rights on your windows device running the VPN client to do this and you should not proceed with setup, if you do not have experience with the windows registry. If this is a business environment or for production use in a business environment, please consult with your IT department before doing anything with this software.

-Although not required, if your deploying this to multiple machines, a method to define registry settings on more than one computer should be considered. Group Policy or an RMM tool can be useful for this. A method should also be in place to silently install this script on each machine in a fleet.

# Installing the software manually:

1. Create a folder on the root of your C:\ drive: C:\NetBirdIPCheck

Copy the following files from the Binaries folder in the repository or provided in the zip release to the C:\NetBirdIPCheck you just created:
CreateTask.bat
DeleteTask.bat
NetbirdPublicIPCheckerService.exe
NetbirdPublicIPCheckerPass.exe
NBCheckTask.xml

2. Create the following registry key : Computer\HKEY_LOCAL_MACHINE\SOFTWARE\NetbirdIPCheck

3. Create the following registry values, in REG_SZ format, string values:

APIToken - A Netbird server API token, you will need to create a service user with admin rights and configure a token for that user. Note the maximum time you can set a token to not expire for, is up to one year. Keep in mind, that you will need to update this registry entry when the token is about to expire and you need to renew it.

NetbirdURL - The URL of your Netbird server. Make sure it is in this format: https://netbird.yourdomain.com:33073. Port 33073 is where the API endpoint lives on self-hosted Netbird servers.

You can set these manually if that's feasible for you, or in an automated fashion using Group Policy, if your running an Active Directory environment or via an RMM solution. You may need to create a script to deploy this in a more automated fashion.

4. in C:\NetBirdIPCheck run CreateTask.bat as Administrator, this will create the "Netbird Public IP Checker Background Task" that automatically starts NetbirdPublicIPCheckerService.exe when Windows starts. This is the EXE that is always running a script to monitor the Netbird server and the posture check for changes to public IP information and will stop and start the Netbird client anytime a change is detected on the server.


# Uninstalling the software
1. Stop the "Netbird Public IP Checker Background Task" in Task Scheduler as an Administrator. Then run DeleteTask.bat in C:\NetBirdIPCheck.
2. Remove the files from C:\NetBirdIPCheck.
3. Remove the registry key Computer\HKEY_LOCAL_MACHINE\SOFTWARE\NetbirdIPCheck and the values within.

# Expected behavior
If the endpoint is behind a public IP address on the "Block Public IPs from VPN" posture check assigned to a group the endpoint is a member of, the VPN will be disconnected but the agent will remain up, just as it does with internal IP addresses natively.