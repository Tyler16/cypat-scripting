#!/bin/bash
set_permissions () {
	file=$1
	chown root:root $file
	chmod 0600 $file
}

append_file () {
	file=$1
	text=$2
	chmod 777 $file
	chattr -ai $file
	echo "$text" >> $file
	set_permissions $file
}

rewrite_file () {
	filename=$1
	file=$2
	chmod 777 $file
	chattr -ai $file
	cat ./ReferenceFiles/$filename > $file
	set_permissions $file
}

unalias -a
append_file ~/.bashrc "unalias -a"
append_file ~/.bashrc "unalias -a"

clear
echo "Aliases have been removed"

if [ "$EUID" -ne 0 ]
then
	echo "Please run as root"
	exit
fi

filesystems=(cramfs freevxfs jffs2 hfs hfsplus udf)

echo "What OS are you using?"
echo "1. Ubuntu 16"
echo "2. Ubuntu 18"
echo "3. Debian 9"
read -p "> " OS

read -p "Enter a password that will be used for every user(except you): " password

read -p "What is your username? " mainUser

while [ true ]
do
	clear
	echo "Choose a task"
	echo "1. Updates"
	echo "2. Users and Passwords"
	echo "3. Local Policies"
	echo "4. Network Security"
	echo "5. Package Management"
	echo "6. Critical Services"
	echo "7. Auditing"
	echo "8. Prohibited files"
	echo "9. Virus, Rootkits and unwanted Scripts"
	echo "10. Booting and File Mounting"
	echo "11. End Script"
	read -p "> " task
	if [ $task = "1" ]
	then
		if [ $OS = "1" ]
		then
			rewrite_file ubuntu16Sources.list /etc/apt/sources.list
			chmod 0640 /etc/apt/sources.list
		fi
		
		rewrite_file 10periodic /etc/apt/apt.conf.d/10periodic
		chmod 0640 /etc/apt/apt.conf.d/10periodic
		rewrite_file 20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
		chmod 0640 /etc/apt/apt.conf.d/20auto-upgrades
		
		apt-get update
		read -p "Do updates now(only if rest of script is ran)? (y/n) " updatePrompt
		if [ $updatePrompt = "y" ]
		then
			echo "Updating, this might take a while"
			apt-get upgrade -y
			apt-get dist-upgrade -y
		fi
	elif [ $task = "2" ]
	then
		echo "Creating file with list of system users"
		cut -d: -f1 /etc/passwd > users.txt
		
		read -p "Use ReadMe for users? (y/n) " readmeUsers
		if [ $readmeUsers = "y" ]
		then
			echo "ReadMe user system not created yet."
		elif [ $readmeUsers = "n" ]
		then
			echo "Enter all users in readme with a single space in between each user(including admins): "
			read -a users
			
			for user in `cat users.txt`
			do
				initialIDDifference=0
				userID=$(id $user | cut -d= -f2 | cut -d"(" -f1)
				if [ $userID = 0 ] && [ $user != "root" ]
				then
					let newID=2000 + $initialIDDifference
					usermod -u $newID $user
					userID=$newID
					((initialIDDifference++))
				fi
				
				if [ $userID -ne 0 ] && [ $user = "root" ]
				then
					usermod -ou 0 root
				fi
				
				if [ $userID -ge 1000 ]
				then
					if [ $user = $mainUser ] || [[ " ${users[@]} " =~ " ${user} " ]]
					then
						echo "${user}:${password}" | chpasswd
			
						read -p "Is user ${user} an authorized admin? (y/n) " adminPrompt
						if [ $adminPrompt = "y" ]
						then
							gpasswd -a $user sudo
							gpasswd -a $user adm
							gpasswd -a $user lpadmin
							gpasswd -a $user sambashare
						else
							gpasswd -d $user sudo
							gpasswd -d $user adm
							gpasswd -d $user lpadmin
							gpasswd -d $user sambashare
						fi
					else
						read -p "Delete user ${user}? (y/n) " deleteUserPrompt
						if [ $deleteUserPrompt = "y" ]
						then
							echo "Deleting user $user"
							deluser --force --remove-all-files $user
						fi
					fi
				fi
			done
		else
			echo "Invalid response, skipping user removal"
		fi
		
		read -p "Are there any users that need to be added? (y/n) " newUser
		if [ $newUser = "y" ]
		then
			echo "Enter usernames of users that need to be created with a single space seperating each user: "
			read -a newUsers
			for user in "${newUsers[@]}"
			do
				useradd $user
				read -p "Should user be an admin? (y/n) " adminPrompt
				if [ adminPrompt = "y" ]
				then
					gpasswd -a $user sudo
					gpasswd -a $user adm
					gpasswd -a $user lpadmin
					gpasswd -a $user sambashare
				fi
			done
		fi
		
		read -p "Are there any new groups that need to be created? (y/n) " newGroup
		if [ $newGroup = "y" ]
		then
			echo "Enter all groups that need to be created with a single space seperating each group: "
			read -a newGroupNames
			for group in "${newGroupNames[@]}"
			do
				groupadd $group
				echo "Enter users that belong in ${group} with a single space seperating each user: "
				read -a groupUsers
				for user in "${groupUsers[@]}"
				do
					usermod -a -G $group $user
				done
			done
		fi
		
		read -p "Are there any groups that need to be modified/checked? (y/n) " modifiedGroup
		if [ $modifiedGroup = "y" ]
		then
			echo "Enter all groups that need to be modified with a single space seperating each group: "
			read -a modifiedGroupNames
			for group in "${modifiedGroupNames[@]}"
			do
				read -ap "Enter all users that should be in group ${group}:" allowedUsers
				
			done
		fi
		
		echo "Locking root account and setting password"
		echo "root:${password}" | chpasswd
		passwd -l root
	elif [ $task = "3" ]
	then
		echo "Setting up lightdm file"
		rm /etc/lightdm/lightdm.conf
		rm -R /etc/lightdm/lightdm.conf.d/*
		touch /etc/lightdm/lightdm.conf
		rewrite_file lightdm.conf /etc/lightdm/lightdm.conf
		
		echo "Preventing su access"
		rewrite_file su /etc/pam.d/su
		
		echo "Setting Password Policies"
		apt-get install libpam-cracklib
		rewrite_file common-password /etc/pam.d/common-password
		rewrite_file login.defs /etc/login.defs
		rewrite_file common-auth /etc/pam.d/common-auth
		
		echo "Setting permissions on user info files and bash history files"
		chown root:root .bash_history
		chmod 640 .bash_history
		chmod 600 /etc/shadow
		
		for file in /etc/sudoers.d/*
		do
			read -p "Remove file ${file} (Only remove if not cyberpatriot or main file)? (y/n) " sudoersPrompt
			if [ $sudoersPrompt = "y"]
			then
				rm $file
			fi
		done
		visudo
	elif [ $task = "4" ]
	then
		echo "Setting up firewall"
		apt-get install ufw
		apt-get install iptables
		ufw enable
		
		echo "Setting hosts file to default"
		rewrite_file hosts /etc/hosts
		
		read -p "Do you want to turn on a VPN(Requires SSH, HTTP and HTTPS ports to be allowed)? (y/n) " VPNPrompt
		if [ $VPNPrompt = "y" ]
		then
			ufw allow 22
			ufw allow 80
			ufw allow 443
			wget https://git.io/vpn -O openvpn-install.sh
			bash openvpn-install.sh
		fi
		
		echo "Setting network settings for sysctl(CIS 1.16 3.1-3)"
		rewrite_file sysctl.conf /etc/sysctl.conf
		sysctl -w net.ipv4.ip_forward=0
		sysctl -w net.ipv4.conf.all.send_redirects=0
		sysctl -w net.ipv4.conf.default.send_redirects=0
		sysctl -w net.ipv4.conf.all.accept_source_route=0
		sysctl -w net.ipv4.conf.default.accept_source_route=0
		sysctl -w net.ipv4.conf.all.accept_redirects=0
		sysctl -w net.ipv4.conf.default.accept_redirects=0
		sysctl -w net.ipv4.conf.all.secure_redirects=0
		sysctl -w net.ipv4.conf.default.secure_redirects=0
		sysctl -w net.ipv4.conf.all.log_martians=1
		sysctl -w net.ipv4.conf.default.log_martians=1
		sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
		sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
		sysctl -w net.ipv4.conf.all.rp_filter=1
		sysctl -w net.ipv4.conf.default.rp_filter=1
		sysctl -w net.ipv4.tcp_syncookies=1
		sysctl -w net.ipv6.conf.all.accept_ra=0
		sysctl -w net.ipv6.conf.default.accept_ra=0
		sysctl -w net.ipv6.conf.all.accept_redirects=0
		sysctl -w nerects=0
		sysctl -w net.ipv4.route.flush=1
		
		echo "Preventing IP Spoofing"
		chmod 777 /etc/host.conf
		echo "nospoof on" >> /etc/host.conf
		chown root:root /etc/host.conf
		chmod 600 /etc/host.conf
		
		echo "Disabling IP forwarding"
		echo "0" > /proc/sys/net/ipv4/ip_forward
	elif [ $task = "5" ]
	then
		read -p "Are there any extra packages that need to be installed? (y/n) " packagePrompt
		if [ packagePrompt="y" ]
		then
			read -ap "Enter all packages that need to be created with a single space seperating each group: " packages
			for package in "${packages[@]}"
			do
				apt-get install $package
			done
		fi
		
		echo "Not allowing unauthenticated packages"
		append_file /etc/apt/apt.conf.d/01-vendor-ubuntu 'APT::Get::AllowUnauthenticated "false";'
		
		echo "Disabling ctrl+alt+delete key sequence"
		systemctl mask ctrl-alt-del.target
		systemctl daemon-reload
		
		echo "Removing hacking tools and vulnerable services(Includes CIS 16 1.5.4)"
		prelink -ua
		apt-get purge -y aircrack-ng alien apktool autofs crack crack-common crack-md5 fcrackzip hydra* irpas *inetd inetutils* john* *kismet* lcrack logkeys *macchanger* *netcat* nfs-common nfs-kernel-server nginx nis *nmap* ophcrack* pdfcrack portmap prelink rarcrack rsh-server rpcbind sipcrack snmp socat socket sucrack tftpd-hpa vnc4server vncsnapshot vtgrab wireshark yersinia *zeitgeist*
		
		read -p "Would you like to remove every game for the system? (y/n): " gamePrompt
		if [ $gamePrompt = "y" ]
		then
			echo "Removing games"
			apt-get purge -y 0ad* 2048-qt 7kaa* a7xpg* abe* aajm acm ace-of-penguins adanaxisgpl* adonthell* airstrike* aisleriot alex4* alien-arena* alienblaster* amoebax* amphetamine* an anagramarama* angband* angrydd animals antigravitaattori ardentryst armagetronad* asc asc-data asc-music astromenace* asylum* atanks* atom4 atomic* attal* auralquiz balder2d* ballerburg ballz* bambam barrage bastet bb bear-factory beneath-a-steel-sky berusky* between billard* biloba* biniax2* black-box blobandconquer* blobby* bloboats blobwars* blockattack blockout2 blocks-of-the-undead* bombardier bomber bomberclone* boswars* bouncy bovo brainparty* briquolo* bsdgames* btanks* bubbros bugsquish bumprace* burgerspace bve* openbve* bygfoot* bzflag* cappuccino cardstories castle-combat cavezofphear ceferino* cgoban *chess* childsplay* chipw chocolate* chromium-bsu* circuslinux* colobot* colorcode connectagram* cookietool *cowsay* crack-attack crafty* crawl* crimson criticalmass* crossfire* csmash* cube2* cultivation curseofwar cutemaze cuyo* cyphesis-cpp* cytadela* *x-rebirth dangen darkplaces* dds deal dealer defendguin* desmume deutex dhewm3* dizzy dodgindiamond2 dolphin-emu* doom-wad-shareware doomsday* dopewars* dossizola* drascula* dvorak7min eboard* edgar* efp einstein ember-media empire* endless-sky* enemylines* enigma* epiphany* etoys etw* excellent-bifurcation extremetuxracer* exult* fairymax fb-music-high ffrenzy fgo fgrun fheroes2-pkg filler fillets-ng* filters five-or-more fizmo* flare* flight-of-the-amazon-queen flightgear* flobopuyo fltk1.1-games fltk1.3-games fofix foobillard* fortune* four-in-a-row freealchemist freecell-solver-bin freeciv* freecol freedink* freedm freedoom freedroid* freegish freeorion* freespace2* freesweep freetennis* freevial fretsonfire* frobtads frogatto frotz frozen-bubble* fruit funguloids* funnyboat gamazons game-data-packager gameclock gamine* garden-of-coloured-lights* gargoyle-free gav* gbrainy gcompris* gearhead* geekcode geki* gemdropx gemrb* geneatd gfceu gfpoken gl-117* glaurung glhack glines glob2* glpeces* gltron gmult gnect gnibbles gnobots2 gnome-breakout gnome-cards-data gnome-hearts gnome-klotski gnome-mahjongg gnome-mastermind gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-tetravex gnomine gnotravex gnotski gnubg* gnubik gnuboy* gnudoq gnugo gnujump* gnuminishogi gnurobbo* gnurobots gnushogi golly gplanarity gpsshogi* granatier granule gravitation gravitywars greed grhino grhino-data gridlock.app groundhog gsalliere gtali gtans gtkballs gtkboard gtkboard gtkpool gunroar* gvrng gweled hachu hannah* hearse hedgewars* heroes* hex-a-hop hexalate hexxagon higan hitori hoichess holdingnuts holotz-castle* hyperrogue* iagno icebreaker ii-esu instead* ioquake3 jester jigzo* jmdlx jumpnbump* jzip kajongg kanagram kanatest kapman katomic kawari8 kball* kblackbox kblocks kbounce kbreakout kcheckers kdegames* kdiamond ketm* kfourinline kgoldrunner khangman kigo kiki-the-nano-bot* kildclient killbots kiriki kjumpingcube klickety klines kmahjongg kmines knavalbattle knetwalk knights kobodeluxe* kolf kollision komi konquest koules kpat krank kraptor* kreversi kshisen ksirk ksnakeduel kspaceduel ksquares ksudoku ktuberling kubrick laby late* lbreakout2* lgc-pg lgeneral* libatlas-cpp-0.6-tools libgemrb libretro-nestopia lierolibre* lightsoff lightyears lincity* linthesia liquidwar* littlewizard* llk-linux lmarbles lmemory lolcat londonlaw lordsawar* love* lskat ltris luola* lure-of-the-temptress macopix-gtk2 madbomber* maelstrom magicmaze magicor* magictouch mah-jong mahjongg mame* manaplus* mancala marsshooter* matanza mazeofgalious* mednafen megaglest* meritous* mess* mgt miceamaze micropolis* minetest* mirrormagic* mokomaze monopd monster-masher monsterz* moon-buggy* moon-lander* moria morris mousetrap mrrescue mttroff mu-cade* mudlet multitet mupen64plus* nestopia nethack* netmaze netpanzer* netris nettoe neverball* neverputt* nexuiz* ninix-aya ninvaders njam* noiz2sa* nsnake numptyphysics ogamesim* omega-rpg oneisenough oneko onscripter oolite* open-invaders* openarena* opencity* openclonk* openlugaru* openmw* openpref openssn* openttd* opentyrian openyahtzee orbital-eunuchs-sniper* out-of-order overgod* pachi pacman* palapeli* pangzero parsec47* passage pathogen pathological pax-britannica* pcsx2 pcsxr peg-e peg-solitaire pegsolitaire penguin-command pente pentobi performous* pescetti petris pgn-extract phalanx phlipple* pianobooster picmi pinball* pingus* pink-pony* pioneers* pipenightdreams* pixbros pixfrogger planarity plee-the-bear* pokerth* polygen* polyglot pong2 powder powermanga* pq prboom-plus* primrose projectl purity* pybik* pybridge* pykaraoke* pynagram pyracerz pyscrabble* pysiogame pysolfc* pysycache* python-pykaraoke python-renpy qgo qonk qstat qtads quadrapassel quake* quarry qxw rafkill* raincat* randtype rbdoom3bfg redeclipse* reminiscence renpy* residualvm* ri-li* rlvm robocode robotfindskitten rockdodger rocksndiamonds rolldice rott rrootage salliere sandboxgamemaker sauerbraten* scid* scorched3d* scottfree scummvm* sdl-ball* seahorse-adventures searchandrescue* sgt-puzzles shogivar* simutrans* singularity* sjaakii sjeng sl slashem* slimevolley* slingshot sm snake4 snowballz solarwolf sopwith spacearyarya spacezero speedpad spellcast sponc spout spring* starfighter* starvoyager* stax steam steamcmd stockfish stormbaancoureur* sudoku supertransball2* supertux* swell-foop tads3-common tagua* tali tanglet* tatan tdfsb tecnoballz* teeworlds* tenace tenmado tennix tetrinet* tetzle tf tf5 tictactoe-ng tint tintin++ tinymux titanion* toga2 tomatoes* tome toppler torcs* tourney-manager trackballs* transcend treil trigger-rally* triplane triplea trophy* tumiki-fighters* tuxfootball tuxmath* tuxpuck tuxtype* tworld* typespeed uci2wb ufoai* uhexen2* uligo unknown-horizons uqm* val-and-rick* vbaexpress vcmi vectoroids viruskiller visualboyadvance* vodovod warmux* warzone2100* wesnoth* whichwayisup widelands* wing* wizznic* wmpuzzle wolf4sdl wordplay wordwarvi* xabacus xball xbill xblast-tnt* xboard xbomb xbubble* xchain xdemineur xdesktopwaves xevil xfireworks xfishtank xflip xfrisk xgalaga* xgammon xinv3d xjig xjokes xjump xletters xmabacus xmahjongg xmoto* xmountains xmpuzzles xonix xpat2 xpenguins xphoon xpilot* xpuzzles xqf xracer* xscavenger xscorch xscreensaver-screensaver-dizzy xshisen xshogi xskat xsok xsol xsoldier xstarfish xsystem35 xteddy xtron xvier xwelltris xword xye yahtzeesharp yamagi-quake2* zangband* zatacka zaz* zec zivot zoom-player
		fi
		
		echo "Installing security applications"
		apt-get install gnupg
	elif [ $task = "6" ]
	then
		read -p "Is FTP a critical service? (y/n) " FTPPrompt
		if [ $FTPPrompt = "y" ]
		then
			apt-get purge *ftp*
			apt-get install ftp
			ufw allow ftp
			ufw allow sftp
			echo "What FTP application is being used?"
			echo "1. vsftpd"
			echo "2. proftpd"
			echo "3. pureftpd"
			echo "4. other"
			read -p "> " FTPApplication
			if [ $FTPApplication = "1" ]
			then
				apt-get install vsftpd
				openssl req -x509 -nodes -keyout /etc/ssl/private/vsftpdkey.pem -out /etc/ssl/certs/vsftpdcert.pem -days 365 -newkey rsa:2048
				rewrite_file vsftpd.conf /etc/vsftpd.conf
				set_permissions /etc/ssl/private/vsftpdkey.pem
				set_permissions /etc/ssl/certs/vsftpdcert.pem
			elif [ $FTPApplication = "2" ]
			then
				apt-get install proftpd-basic
				openssl req -x509 -nodes -keyout /etc/ssl/private/proftpdkey.pem -out /etc/ssl/certs/proftpdcert.pem -days 365 -newkey rsa:2048
				rewrite_file tls.conf /etc/proftpd/tls.conf
				rewrite_file proftpd.conf /etc/proftpd/proftpd.conf
				set_permissions /etc/ssl/private/proftpdkey.pem
				set_permissions /etc/ssl/certs/proftpdcert.pem
			elif [ $FTPApplication = "3" ]
			then
				apt-get install pure-ftpd
				openssl req -x509 -nodes -keyout /etc/ssl/private/pureftpdkey.pem -out /etc/ssl/certs/proftpcert.pem -days 365 -newkey rsa:2048 -sha256
				/usr/local/sbin/pure-ftpd --tls=2
				set_permissions root:root /etc/ssl/private/pureftpdkey.pem
				set_permissions /etc/ssl/certs/pureftpdcert.pem
			elif [ $FTPApplication = "4" ]
			then
				read -p "Enter application for FTP and search how to secure said application: " FTPapp
				apt-get install $FTPapp
			else
				echo "Invalid option"
			fi
		elif [ $FTPPrompt = "n" ]
		then
			apt-get purge *ftp*
			ufw deny ftp
			ufw deny sftp
			ufw deny saft
			ufw deny ftps-data
			ufw deny ftps
		else
			echo "Invalid option"
		fi
		
		read -p "Is SSH a critical service? (y/n) " SSHPrompt
		if [ $SSHPrompt = "y" ]
		then
			apt-get install ssh
			apt-get install openssh
			apt-get install openssh-server
			ufw allow ssh
			rewrite_file sshd_config /etc/ssh/sshd_config
			chmod +w /etc/ssh/sshd_config
			read -ap "Enter users that need SSH access with a single space seperating each user: " sshUsers
			echo "AllowUsers $sshUsers" >> /etc/ssh/sshd_config
			echo "DenyUsers" >> /etc/ssh/sshd_config
			read -p "What port should SSH use?" SSHPort
			sed '5 s/22/${SSHPort}/' /etc/ssh/sshd_config
			chmod -w /etc/ssh/sshd_config
			mkdir ~/.ssh
			chmod 0700 ~/.ssh
			chown root:root ~/.ssh
			ssh-keygen -t rsa
		elif [ $SSHPrompt = "n" ]
		then
			apt-get purge ssh
			apt-get purge openssh
			apt-get purge openssh-server
			ufw deny ssh
		else
			echo "Invalid option"
		fi

		read -p "Is Apache a critical service? (y/n) " ApachePrompt
		if [ $ApachePrompt = "y" ]
		then
			apt-get install apache2
			ufw allow http
			ufw allow https
			groupadd -r apache
			useradd apache -r -G apache -d /var/www -s /sbin/nologin
			passwd -l apache
			chown -R root:root /var/lock/apache2
			chmod 740 /var/lock/apache2
			chown -R root:root /var/run/apache2
			chmod 740 /var/run/apache2
			chown -R root:apache /var/log/apache2 
			chmod 740 /var/log/apache2
		elif [ $ApachePrompt = "n" ]
		then
			apt-get purge apache2
			ufw deny http
			ufw deny https
			rm -r /var/www/*
		else
			echo "Invalid option"
		fi
    
		read -p "Is Samba a critical service? (y/n) " SambaPrompt
		if [ $SambaPrompt = "y" ]
		then
			apt-get install samba
			ufw allow netbios-ns
			ufw allow netbios-dgm
			ufw allow netbios-ssn
			ufw allow microsoft-ds
		elif [ $SambaPrompt = "n" ]
		then
			apt-get purge samba*
			apt-get purge smb
			ufw deny netbios-ns
			ufw deny netbios-dgm
			ufw deny netbios-ssn
			ufw deny microsoft-ds
		else
			echo "Invalid option"
		fi
    
		read -p "Is DNS a critical service? (y/n) " DNSPrompt
		if [ $DNSPrompt = "y" ]
		then
			apt-get install bind9
			ufw allow domain
		elif [ $DNSPrompt = "n" ]
		then
			apt-get purge bind9
			ufw deny domain
		else
			echo "Invalid option"
		fi
		
		read -p "Is SQL a critical service? (y/n) " SQLPrompt
		if [ $SQLPrompt = "y" ]
		then
			echo "What SQL service are you using?"
			echo "1. MySQL"
			echo "2. PostgreSQL"
			echo "3. Other"
			read -p "> " SQLPackage
			if [ $SQLPackage = "1" ]
			then
				apt-get purge postgresql
				apt-get install mysql-server
				mysql_secure_installation
				rewrite_file my.cnf /etc/mysql/my.cnf
			elif [ $SQLPackage = "2" ]
			then
				apt-get purge mysql-server
				apt-get install postgresql
			elif [ $SQLPackage = "3" ]
			then
				read -p "Enter package name and look up how to secure it: " SQLApplication
				apt-get install $SQLApplication
			else
				echo "Invalid response"
			fi
		elif [ $SQLPrompt = "n" ]
		then
			ufw deny ms-sql-s
			ufw deny ms-sql-m
			ufw deny mysql
			ufw deny mysql-proxy
			ufw deny postgresql
			apt-get purge mysql*
			apt-get purge postgresql
		else
			echo "Invalid option"
		fi
    
		read -p "Is Telnet a critical service? (y/n) " TelnetPrompt
		if [ $TelnetPrompt = "y" ]
		then
			apt-get install telnet
			ufw allow telnet
		elif [ $TelnetPrompt = "n" ]
		then
			apt-get purge telnet
			apt-get purge telnetd
			ufw deny telnet
		else
			echo "Invalid option"
		fi
		
		read -p "Are mail services required? (y/n) " mailPrompt
		if [ $mailPrompt = "y" ]
		then
			ufw allow smtp
			ufw allow pop2
			ufw allow pop3
			ufw allow imap2
			ufw allow imaps
			ufw allow pop3s
		elif [ $mailPrompt = "n" ]
		then
			apt-get purge dovecot
			ufw deny smtp
			ufw deny pop2
			ufw deny pop3
			ufw deny imap2
			ufw deny imaps
			ufw deny pop3s
		else
			echo "Invalid option"
		fi
		
		read -p "Is printing required? (y/n) " printPrompt
		if [ $printPrompt = "y" ]
		then
			ufw allow ipp
			ufw allow cups
			ufw allow printer
		elif [ $printPrompt = "n" ]
		then
			ufw deny ipp
			ufw deny cups
			ufw deny printer
		else
			echo "Invalid option"
		fi
	elif [ $task = "7" ]
	then
		apt-get install auditd
		auditctl -e 1
		chown root:root /etc/audit
		chmod 0700 /etc/audit
	elif [ $task = "8" ]
	then
		read -p "Run a deep scan(takes longer)? (y/n) " scanType
		echo "Finding and listing media files"
		touch media-files.txt
		
		if [ $scanType = "y" ]
		then
			find / -type f -iname "*.3g2" >> media-files.txt
			find / -type f -iname "*.3gp" >> media-files.txt
			find / -type f -iname "*.mov" >> media-files.txt
			find / -type f -iname "*.amv" >> media-files.txt
			find / -type f -iname "*.asf" >> media-files.txt
			find / -type f -iname "*.avi" >> media-files.txt
			find / -type f -iname "*.drc" >> media-files.txt
			find / -type f -iname "*.flv" >> media-files.txt
			find / -type f -iname "*.f4v" >> media-files.txt
			find / -type f -iname "*.f4p" >> media-files.txt
			find / -type f -iname "*.f4a" >> media-files.txt
			find / -type f -iname "*.f4b" >> media-files.txt
			find / -type f -iname "*.m4v" >> media-files.txt
			find / -type f -iname "*.mkv" >> media-files.txt
			find / -type f -iname "*.mng" >> media-files.txt
			find / -type f -iname "*.mov" >> media-files.txt
			find / -type f -iname "*.mp4" >> media-files.txt
			find / -type f -iname "*.m4p" >> media-files.txt
			find / -type f -iname "*.m4v" >> media-files.txt
			find / -type f -iname "*.mpg" >> media-files.txt
			find / -type f -iname "*.mp2" >> media-files.txt
			find / -type f -iname "*.mpeg" >> media-files.txt
			find / -type f -iname "*.mpe" >> media-files.txt
			find / -type f -iname "*.mpv" >> media-files.txt
			find / -type f -iname "*.m2v" >> media-files.txt
			find / -type f -iname "*.MTS" >> media-files.txt
			find / -type f -iname "*.M2TS" >> media-files.txt
			find / -type f -iname "*.mxf" >> media-files.txt
			find / -type f -iname "*.nsv" >> media-files.txt
			find / -type f -iname "*.ogg" >> media-files.txt
			find / -type f -iname "*.ogv" >> media-files.txt
			find / -type f -iname "*.qt" >> media-files.txt
			find / -type f -iname "*.rm" >> media-files.txt
			find / -type f -iname "*.rmvb" >> media-files.txt
			find / -type f -iname "*.roq" >> media-files.txt
			find / -type f -iname "*.svi" >> media-files.txt
			find / -type f -iname "*.ts" >> media-files.txt
			find / -type f -iname "*.vob" >> media-files.txt
			find / -type f -iname "*.webm" >> media-files.txt
			find / -type f -iname "*.wmv" >> media-files.txt
			find / -type f -iname "*.yuv" >> media-files.txt

			find / -type f -iname "*.8svx" >> media-files.txt
			find / -type f -iname "*.aa" >> media-files.txt
			find / -type f -iname "*.aac" >> media-files.txt
			find / -type f -iname "*.aax" >> media-files.txt
			find / -type f -iname "*.act" >> media-files.txt
			find / -type f -iname "*.aiff" >> media-files.txt
			find / -type f -iname "*.alac" >> media-files.txt
			find / -type f -iname "*.amr" >> media-files.txt
			find / -type f -iname "*.ape" >> media-files.txt
			find / -type f -iname "*.au" >> media-files.txt
			find / -type f -iname "*.awb" >> media-files.txt
			find / -type f -iname "*.cda" >> media-files.txt
			find / -type f -iname "*.dct" >> media-files.txt
			find / -type f -iname "*.dss" >> media-files.txt
			find / -type f -iname "*.dvf" >> media-files.txt
			find / -type f -iname "*.flac" >> media-files.txt
			find / -type f -iname "*.gsm" >> media-files.txt
			find / -type f -iname "*.iklax" >> media-files.txt
			find / -type f -iname "*.ivs" >> media-files.txt
			find / -type f -iname "*.m4a" >> media-files.txt
			find / -type f -iname "*.m4b" >> media-files.txt
			find / -type f -iname "*.mmf" >> media-files.txt
			find / -type f -iname "*.mp3" >> media-files.txt
			find / -type f -iname "*.mpc" >> media-files.txt
			find / -type f -iname "*.msv" >> media-files.txt
			find / -type f -iname "*.nmf" >> media-files.txt
			find / -type f -iname "*.nsf" >> media-files.txt
			find / -type f -iname "*.oga" >> media-files.txt
			find / -type f -iname "*.opus" >> media-files.txt
			find / -type f -iname "*.mogg" >> media-files.txt
			find / -type f -iname "*.ra" >> media-files.txt
			find / -type f -iname "*.raw" >> media-files.txt
			find / -type f -iname "*.rf64" >> media-files.txt
			find / -type f -iname "*.sln" >> media-files.txt
			find / -type f -iname "*.tta" >> media-files.txt
			find / -type f -iname "*.voc" >> media-files.txt
			find / -type f -iname "*.vox" >> media-files.txt
			find / -type f -iname "*.wav" >> media-files.txt
			find / -type f -iname "*.wma" >> media-files.txt
			find / -type f -iname "*.wv" >> media-files.txt

			find / -type f -iname "*.bmp" >> media-files.txt
			find / -type f -iname "*.eps" >> media-files.txt
			find / -type f -iname "*.gif" >> media-files.txt
			find / -type f -iname "*.gifv" >> media-files.txt
			find / -type f -iname "*.heif" >> media-files.txt
			find / -type f -iname "*.img" >> media-files.txt
			find / -type f -iname "*.jpeg" >> media-files.txt
			find / -type f -iname "*.jpg" >> media-files.txt
			find / -type f -iname "*.jfif" >> media-files.txt
			find / -type f -iname "*.png" >> media-files.txt
			find / -type f -iname "*.tif" >> media-files.txt
			find / -type f -iname "*.tiff" >> media-files.txt
			find / -type f -iname "*.webp" >> media-files.txt

			for file in `cat media-files.txt`
			do
				read -p "Remove file ${$file} (say no if cyberpatriot file)? (y/n)" fileRemovePrompt
				if [ fileRemovePrompt = "y" ]
				then
					rm -rf $file
				fi
			done
		elif [ $scanType = "n" ]
		then
			find /home -type f -iname "*.mov" >> media-files.txt
			find /home -type f -iname "*.mp4" >> media-files.txt
			find /home -type f -iname "*.webm" >> media-files.txt
			find /home -type f -iname "*.ogg" >> media-files.txt
			find /home -type f -iname "*.mp3" >> media-files.txt
			find /home -type f -iname "*.wav" >> media-files.txt
			find /home -type f -iname "*.gif" >> media-files.txt
			find /home -type f -iname "*.jpeg" >> media-files.txt
			find /home -type f -iname "*.jpg" >> media-files.txt
			find /home -type f -iname "*.png" >> media-files.txt
			for file in `cat media-files.txt`
			do
				read -p "Remove file ${$file} (say no if cyberpatriot file)? (y/n)" fileRemovePrompt
				if [ fileRemovePrompt = "y" ]
				then
					rm -rf $file
				fi
			done
		else
			echo "Invalid response, skipping"
		fi
	elif [ $task = "9" ]
	then
		echo "Getting rid of shosts files"
		find / -name "*.shosts" -type f -delete
		find / -name "shosts.equiv" -type f -delete
		
		echo "Stopping startup scripts"
		echo > /etc/rc.local
		echo "exit 0" >> /etc/rc.local
		chown root:root /etc/rc.local
		chmod 640 /etc/rc.local
		
		echo "Removing scripts from /bin"
		find /bin/ -name "*.sh" -type f -delete
		
		echo "Removing crontabs and changing crontab access"
		crontab -r
		rm /etc/cron.deny
		rm /etc/at.deny
		echo "root" > /etc/cron.allow
		echo "root" > /etc/at.allow
		
		echo "Installing rootkit tools"
		apt-get install chkrootkit
		apt-get install rkhunter
		
		echo "Installing antivirus"
		apt-get install clamav
		freshclam
		read -p "Do virus scan now(could take a while)? (y/n) " virusPrompt
		if [ $virusPrompt = "y" ]
		then
			clamscan
		fi
	elif [ $task = "10" ]
	then
		echo "Disabling unused filesystems(CIS 16 and 14 1.1.1.1-6)"
		touch /etc/modprobe.d/Cypat.conf
		for filesystem in "${filesystems[@]}"
		do
			echo "install ${filesystem} /bin/true" >> /etc/modprobe.d/cypat.conf
			rmmod $filesystem
		done
		set_permissions /etc/modprobe.d/cypat.conf
		chown root:root /etc/modprobe.d/cypat.conf
		
		echo "Setting up sticky bit on world writeable directories(CIS 16 and 14 1.1.20)"
		df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t
		
		echo "Disabling automounting(CIS 16 1.1.21)"
		systemctl disable autofs
		
		echo "Setting up filesystem integrity checks(CIS 16 and 14 1.3.1)"
		apt-get install aide aide-common
		aideinit
		
		echo "Setting up boot security(CIS 16 and 14 1.4.1-2)"
		chown root:root /boot/grub/grub.cfg
		chmod 0700 /boot/grub/grub.cfg
		
		echo "Please set secure password for boot"
		grub-mkpasswd-pbkdf2
		echo "Copy hash of password above"
		read -p "Paste password hash here: " grubPassword
		rewrite_file 00_header /etc/grub.d/00_header
		chmod +w /etc/grub.d/00_header
		echo 'cat <<EOF' >> /etc/grub.d/00_header
		echo 'set superusers="${mainUser}"' >> /etc/grub.d/00_header
		echo 'password pbkdf2 ${mainUser} ${grubPassword}' >> /etc/grub.d/00_header
		echo 'EOF' >> /etc/grub.d/00_header
		chmod 600 /boot/grub.d/00_header
		
		echo "Doing additional process hardening (CIS 16 1.5.1 and 1.5.3)"
		rewrite_file limits.conf /etc/security/limits.conf
		sysctl -w fs.suid_dumpable=0
		sysctl -w kernel.randomize_va_space=2
		
		echo "Configuring AppArmor (CIS 16 1.6(not using selinux))"
		apt-get install apparmor apparmor-profiles libpam-apparmor
		aa-enforce /etc/apparmor.d/*
		rewrite_file grub /etc/default/grub
		
		echo "Setting up banners and messages (CIS 16 1.7)"
		touch /etc/motd
		echo "Hello and welcome to fortnite central" >> /etc/motd
		chown root:root /etc/motd
		chmod 640 /etc/motd
		echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue
		chown root:root /etc/issue
		chmod 640 /etc/issue
		echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue.net
		chown root:root /etc/issue.net
		chmod 640 /etc/issue.net
	elif [ $task = "11" ]
	then
		exit
	else
		echo "Invalid option, choose again"
	fi
done
