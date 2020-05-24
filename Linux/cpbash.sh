#!/bin/bash
append_file {
  file=$1
  text=$2
  chmod +rw $file
  chattr -ai $file
  echo "$text" >> $file
}

rewrite_file {
  filename=$1
  file=$2
  chmod +rw $file
  chattr -ai $file
  cat ./$filename > $file
}

unalias -a

append_file ~/.bashrc "unalias -a"
chmod -rw ~/.bashrc
chattr +ai

append_file ~/.bashrc "unalias -a"
chmod -rw /root/.bashrc
clear
echo "Aliases have been removed"

if [ "$EUID" -ne 0 ]
then
  echo "Please run as root"
  exit
fi

echo "What OS are you using?"
echo "1. Ubuntu 16"
echo "2. Ubuntu 14"
echo "3. Debian"
read -p "> " OS

read -p "What is your username? " mainUser

while [ true ]
do
  clear
  echo "Choose a task"
  echo "1. Users and Passwords"
  echo "2. Updates"
  echo "3. Network Security"
  echo "4. Package Management"
  echo "5. Critical Services"
  echo "6. Auditing"
  echo "7. End Script"
  read -p "> " task
  if [ $task = "1" ]
  then
    read -p "Use ReadMe for users? (y/n) " readmeUsers
    if [ $readmeUsers = "y" ]
    then
      echo "ReadMe user system not created yet."
    fi
    elif [ $readmeUsers = "n" ]
    then
      read -ap "Enter all users in readme with a single space in between each user." users
    fi
    else
      echo "Invalid response, skipping user removal"
    fi
    
    read -p "Are there any users that need to be added? (y/n) " newUser
    if [ $newUser = "y" ]
    then
      read -ap "Enter usernames of users that need to be created with a single space seperating each user: " newUsers
      for user in "${newUsers[@]}"
      do
        adduser $user
      done
    fi
    
    read -p "Are there any new groups that need to be created? (y/n) " newGroup
    if [ $newGroup = "y" ]
    then
      read -ap "Enter all groups that need to be created with a single space seperating each group: " newGroupNames
      for group in "${newGroupNames[@]}"
      do
        addgroup $group
        read -ap "Enter users that belong in ${group} with a single space seperating each user: " groupUsers
        for user in "${groupUsers[@]}"
        do
          adduser $user $group
        done
      done
    fi
    
    echo "Setting Password Policies"
    apt-get install libpam-cracklib
    rewrite_file common-password /etc/pam.d/common-password
    rewrite_file login.defs /etc/login.defs
    rewrite_file common-auth /etc/pam.d/common-auth
    chown root:root /etc/pam.d/common-password
    chmod 600 /etc/pam.d/common-password
    chown root:root /etc/login.defs
    chmod 600 /etc/login.defs
    chown root:root /etc/pam.d/common-auth
    chmod 600 /etc/common-auth
  fi
  elif [ $task = "2" ]
  then
    read -p "Do updates now? (y/n) " updatePrompt
    if [ $updatePrompt = "y" ]
    then
      echo "Updating, this might take a while"
      apt-get update
      apt-get upgrade -y
      apt-get dist-upgrade -y
    fi
  fi
  elif [ $task = "3" ]
  then
    apt-get install ufw
    apt-get install iptables
    ufw enable
  fi
  elif [ $task = "4" ]
  then
    read -p "Are there any extra packages that need to be installed? (y/n) " packagePrompt
    if [ packagePrompt="y" ]
    then
      read -ap "Enter all packages that need to be created with a single space seperating each group: " packages
      for package in "${packages[@]}"
      do
        apt-get install $package
      done
      
      echo "Removing hacking tools and vulnerable services"
      apt-get purge aircrack-ng alien apktool autofs crack crack-common crack-md5 fcrackzip gamconqueror hashcat hydra* irpas *inetd inetutils* john* *kismet* lcrack *netcat* ncat nfs-common nfs-kernel-server nginx *nmap* ophcrack* portmap logkeys *macchanger* pdfcrack pixiewps rarcrack rpcbind sbd sipcrack snmp socat sock socket sucrack vnc4server vncsnapshot vtgrab wireshark yersinia *zeitgeist*
      
      echo "Removing games"
      apt-get purge 0ad* 2048-qt 4digit 7kaa* a7xpg* abe* aajm acm ace-of-penguins adanaxisgpl* adonthell* airstrike* aisleriot alex4* alien-arena* alienblaster* amoebax* amphetamine* an anagramarama* angband* angrydd animals antigravitaattori ardentryst armagetronad* asc asc-data asc-music ascii-jump assultcube* astromenace* asylum* atanks* atom4 atomic* attal* auralquiz balder2d* ballerburg ballz* bambam barrage bastet bb bear-factory beneath-a-steel-sky berusky* between billard* biloba* biniax2* black-box blobandconquer* blobby* bloboats blobwars* blockattack blockout2 blocks-of-the-undead* bombardier bomber bomberclone* boswars* bouncy bovo brainparty* briquolo* bsdgames* btanks* bubbros bugsquish bumprace* burgerspace bve* openbve* bygfoot* bzflag* cappuccino cardstories castle-combat cavezofphear ceferino* cgoban *chess* childsplay* chipw chocolate* chromium-bsu* circuslinux* colobot* colorcode connectagram* cookietool *cowsay* crack-attack crafty* crawl* crimson criticalmass* crossfire* crrcism* csmash* cube2* cultivation curseofwar cutemaze cuyo* cyphesis-cpp* cytadela* *x-rebirth dangen darkplaces* dds deal dealer defendguin* desmume deutex dhewm3* dizzy dodgindiamond2 dolphin-emu* doom-wad-shareware doomsday* dopewars* dossizola* drascula* dvorak7min eboard* edgar* efp einstein ember-media empire* endless-sky* enemylines* enigma* epiphany* etoys etw* excellent-bifurcation extremetuxracer* exult* fairymax fb-music-high ffrenzy fgo fgrun fheroes2-pkg filler fillets-ng* filters five-or-more fizmo* flare* flight-of-the-amazon-queen flightgear* flobopuyo fltk1.1-games fltk1.3-games fofix foobillard* fortune* four-in-a-row freealchemist freecell-solver-bin freeciv* freecol freedink* freedm freedoom freedroid* freegish freeorion* freespace2* freesweep freetennis* freevial fretsonfire* frobtads frogatto frotz frozen-bubble* fruit funguloids* funnyboat gamazons game-data-packager gameclock gamine* garden-of-coloured-lights* gargoyle-free gav* gbrainy gcompris* gearhead* geekcode geki* gemdropx gemrb* geneatd gfceu gfpoken gl-117* glaurung glhack glines glob2* glpeces* gltron gmult gnect gnibbles gnobots2 gnome-breakout gnome-cards-data gnome-hearts gnome-klotski gnome-mahjongg gnome-mastermind gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-tetravex gnomine gnotravex gnotski gnubg* gnubik gnuboy* gnudoq gnugo gnujump* gnuminishogi gnurobbo* gnurobots gnushogi golly gomoko.app gplanarity gpsshogi* granatier granule gravitation gravitywars greed grhino grhino-data gridlock.app groundhog gsalliere gtali gtans gtkballs gtkboard gtkboard gtkpool gunroar* gvrng gweled hachu hannah* hearse hedgewars* heroes* hex-a-hop hexalate hexxagon higan hitori hoichess holdingnuts holotz-castle* hyperrogue* iagno icebreaker ii-esu ifon instead* ioquake3 jester jigzo* jmdlx jumpnbump* jzip kajongg kanagram kanatest kapman katomic kawari8 kball* kblackbox kblocks kbounce kbreakout kcheckers kdegames* kdiamond ketm* kfourinline kgoldrunner khangman kigo kiki-the-nano-bot* kildclient killbots kiriki kjumpingcube klickety klines kmahjongg kmines knavalbattle knetwalk knights kobodeluxe* kolf kollision komi konquest koules kpat krank kraptor* kreversi kshisen ksirk ksnakeduel kspaceduel ksquares ksudoku ktuberling kubrick laby late* lbreakout2* lgc-pg lgeneral* libatlas-cpp-0.6-tools libgemrb libretro-nestopia lierolibre* lightsoff lightyears lincity* linthesia liquidwar* littlewizard* llk-linux lmarbles lmemory lolcat londonlaw lordsawar* love* lskat ltris luola* lure-of-the-temptress macopix-gtk2 madbomber* maelstrom magicmaze magicor* magictouch mah-jong mahjongg mame* manaplus* mancala marsshooter* matanza mazeofgalious* mednafen megaglest* meritous* mess* mgt miceamaze micropolis* minetest* mirrormagic* mokomaze monopd monster-masher monsterz* moon-buggy* moon-lander* moria morris mousetrap mrrescue mttroff mu-cade* mudlet multitet mupen64plus* nestopia nethack* netmaze netpanzer* netris nettoe neverball* neverputt* nexuiz* nikiwi* ninix-aya ninvaders njam* noiz2sa* nsnake numptyphysics ogamesim* omega-rpg oneisenough oneko onscripter oolite* open-invaders* openarena* opencity* openclonk* openlugaru* openmw* openpref openssn* openttd* opentyrian openyahtzee orbital-eunuchs-sniper* out-of-order overgod* pachi pacman* palapeli* pangzero parsec47* passage pathogen pathological pax-britannica* pcsx2 pcsxr peg-e peg-solitaire pegsolitaire penguin-command pente pentobi performous* pescetti petris pgn-extract phalanx phlipple* pianobooster picmi pinball* pingus* pink-pony* pioneers* pipenightdreams* pipwalker pixbros pixfrogger planarity plee-the-bear* pokerth* polygen* polyglot pong2 powder powermanga* pq prboom-plus* primrose projectl purity* pybik* pybridge* pykaraoke* pynagram pyracerz pyscrabble* pysiogame pysolfc* pysycache* python-pykaraoke python-renpy qgo qonk qstat qtads quadrapassel quake* quarry qxw rafkill* raincat* randtype rbdoom3bfg redeclipse* reminiscence renpy* residualvm* ri-li* rlvm robocode robotfindskitten rockdodger rocksndiamonds rolldice rott rrootage salliere sandboxgamemaker sauerbraten* scid* scorched3d* scottfree scummvm* sdl-ball* seahorse-adventures searchandrescue* sgt-puzzles shogivar* simutrans* singularity* sjaakii sjeng sl slashem* slimevolley* slingshot sludge-empire sm snake4 snowballz solarwolf sopwith spacearyarya spacezero speedpad spellcast sponc spout spring* starfighter* starvoyager* stax steam steamcmd stockfish stormbaancoureur* sudoku supertransball2* supertux* swell-foop tads3-common tagua* tali tanglet* tatan tdfsb tecnoballz* teeworlds* tenace tenmado tennix tetrinet* tetzle tf tf5 tictactoe-ng tint tintin++ tinymux titanion* toga2 tomatoes* tome toppler torcs* tourney-manager trackballs* transcend treil trigger-rally* triplane triplea trophy* tumiki-fighters* tuxfootball tuxmath* tuxpuck tuxtype* tworld* typespeed uci2wb ufoai* uhexen2* uligo unknown-horizons uqm* val-and-rick* vbaexpress vcmi vectoroids viruskiller visualboyadvance* vodovod warmux* warzone2100* wesnoth* whichwayisup widelands* wing* wizznic* wmpuzzle wolf4sdl wordplay wordwarvi* xabacus xball xbill xblast-tnt* xboard xbomb xbubble* xchain xdemineur xdesktopwaves xevil xfireworks xfishtank xflip xfrisk xgalaga* xgammon xinv3d xjig xjokes xjump xletters xmabacus xmahjongg xmile xmoto* xmountains xmpuzzles xonix xpat2 xpenguins xphoon xpilot* xpuzzles xqf xracer* xscavenger xscorch xscreensaver-screensaver-dizzy xshisen xshogi xskat xsok xsol xsoldier xstarfish xsystem35 xteddy xtron xvier xwelltris xword xye yahtzeesharp yamagi-quake2* zangband* zatacka zaz* zec zivot zoom-player
    fi
  fi
  elif [ $task = "5" ]
  then
    read -p "Is SSH a critical service? (y/n) " SSHPrompt
    if [ $SSHPrompt = "y" ]
    then
      apt-get install ssh
      apt-get install openssh
      apt-get install openssh-server
      ufw allow ssh
      rewrite_file sshd_config /etc/ssh/sshd_config
      read -ap "Enter users that need SSH access with a single space seperating each user: " sshUsers
      echo "AllowUsers $sshUsers" >> /etc/ssh/sshd_config
      echo "DenyUsers" >> /etc/ssh/sshd_config
      read -p "What port should SSH use?" SSHPort
      sed '5 s/22/${SSHPort}/' /etc/ssh/sshd_config
      chown root:root /etc/ssh/sshd_config
      chmod 600 /etc/ssh/sshd_config
      chattr +ai /etc/ssh/sshd_config
      mkdir ~/.ssh
      chmod 700 ~/.ssh
      chown root:root ~/.ssh
      ssh-keygen -t rsa
    fi
    elif [ $SSHPrompt = "n" ]
    then
      apt-get purge ssh
      apt-get purge openssh
      apt-get purge openssh-server
      ufw deny ssh
    fi
    else
      echo "Invalid option"
    fi
    
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
	chown root:root /etc/vsftpd.conf
	chmod 600 /etc/vsftpd.conf
	chattr +ai /etc/vsftpd.conf
	chown root:root /etc/ssl/private/vsftpdkey.pem
	chmod 600 /etc/ssl/private/vsftpdkey.pem
	chattr +ai /etc/ssl/private/vsftpdkey.pem
	chown root:root /etc/ssl/certs/vsftpdcert.pem
	chmod 600 /etc/ssl/certs/vsftpdcert.pem
	chattr +ai /etc/ssl/certs/vsftpdcert.pem
      fi
      elif [ $FTPApplication = "2" ]
      then
      	apt-get install proftpd-basic
      	openssl req -x509 -nodes -keyout /etc/ssl/private/proftpdkey.pem -out /etc/ssl/certs/proftpdcert.pem -days 365 -newkey rsa:2048
	rewrite_file tls.conf /etc/proftpd/tls.conf
	rewrite_file proftpd.conf /etc/proftpd/proftpd.conf
	chown root:root /etc/proftpd/proftpd.conf
	chmod 600 /etc/proftpd/proftpd.conf
	chattr +ai /etc/proftpd/proftpd.conf
	chown root:root /etc/proftpd/tls.conf
	chmod 600 /etc/proftpd/tls.conf
	chattr +ai /etc/proftpd/tls.conf
	chown root:root /etc/ssl/private/proftpdkey.pem
	chmod 600 /etc/ssl/private/proftpdkey.pem
	chattr +ai /etc/ssl/private/proftpdkey.pem
	chown root:root /etc/ssl/certs/proftpdcert.pem
	chmod 600 /etc/ssl/certs/proftpdcert.pem
	chattr +ai /etc/ssl/certs/proftpdcert.pem
      fi
      elif [ $FTPApplication = "3" ]
      then
      	apt-get install pure-ftpd
	openssl req -x509 -nodes -keyout /etc/ssl/private/pureftpdkey.pem -out /etc/ssl/certs/proftpcert.pem -days 365 -newkey rsa:2048 -sha256
	/usr/local/sbin/pure-ftpd --tls=2
	chown root:root /etc/ssl/private/pureftpdkey.pem
	chmod 600 /etc/ssl/private/pureftpdkey.pem
	chattr +ai /etc/ssl/private/pureftpdkey.pem
	chown root:root /etc/ssl/certs/pureftpdcert.pem
	chmod 600 /etc/ssl/certs/pureftpdcert.pem
	chattr +ai /etc/ssl/certs/pureftpdcert.pem
      fi
      elif [ $FTPApplication = "4" ]
      then
      	read -p "Enter application for FTP and search how to secure said application: " FTPapp
	apt-get install $FTPapp
      fi
      else
      	echo "Invalid option"
      fi
    fi
    elif [ $FTPPrompt = "n" ]
    then
      apt-get purge *ftp*
      ufw deny ftp
      ufw deny sftp
      ufw deny saft
      ufw deny ftps-data
      ufw deny ftps
    fi
    else
      echo "Invalid option"
    fi
    
    read -p "Is Apache a critical service? (y/n) " ApachePrompt
    if [ $ApachePrompt = "y" ]
    then
      apt-get install apache2
      ufw allow http
      ufw allow https
      rm -r /var/www/*
    fi
    elif [ $ApachePrompt = "n" ]
      apt-get purge apache2
      ufw deny http
      ufw deny https
      rm -r /var/www/*
    then
    fi
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
    fi
    elif [ $SambaPrompt = "n" ]
    then
      apt-get purge samba*
      apt-get purge smb
      ufw deny netbios-ns
      ufw deny netbios-dgm
      ufw deny netbios-ssn
      ufw deny microsoft-ds
    fi
    else
      echo "Invalid option"
    fi
    
    read -p "Is DNS a critical service? (y/n) " DNSPrompt
    if [ $DNSPrompt = "y" ]
    then
      apt-get install bind9
      ufw allow domain
    fi
    elif [ $DNSPrompt = "n" ]
    then
      apt-get purge bind9
      ufw deny domain
    fi
    else
      echo "Invalid option"
    fi
    
    read -p "Is DHCP a critical service? (y/n) " DHCPPrompt
    if [ $DHCPPrompt = "y" ]
    then
    fi
    elif [ $DHCPPrompt = "n" ]
    then
    fi
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
      	apt-get install mysql-server
	mysql_secure_installation
      fi
      elif [ $SQLPackage = "2" ]
      then
      	apt-get install postgresql
      fi
      elif [ $SQLPackage = "3" ]
      then
      	read -p "Enter package name and look up how to secure it: " SQLApplication
	apt-get install $SQLApplication
      fi
      else
      	echo "Invalid response"
      fi
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
    fi
    else
      echo "Invalid option"
    fi
    
    read -p "Is Telnet a critical service? (y/n) " TelnetPrompt
    if [ $TelnetPrompt = "y" ]
    then
      apt-get install telnet
      ufw allow telnet
    fi
    elif [ $TelnetPrompt = "n" ]
    then
      apt-get purge telnet
      ufw deny telnet
    fi
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
    fi
    elif [ $mailPrompt = "n" ]
    then
      ufw deny smtp
      ufw deny pop2
      ufw deny pop3
      ufw deny imap2
      ufw deny imaps
      ufw deny pop3s
    fi
    else
      echo "Invalid option"
    fi
    
    read -p "Is printing required? (y/n) " printPrompt
    if [ $printPrompt = "y" ]
    then
      ufw allow ipp
      ufw allow cups
      ufw allow printer
    fi
    elif [ $printPrompt = "n" ]
    then
      ufw deny ipp
      ufw deny cups
      ufw deny printer
    fi
    else
      echo "Invalid option"
    fi
  fi
  elif [ $task = "6" ]
  then
    apt-get install auditd
    auditctl -e 1
  fi
  elif [ $task = "7" ]
  then
    exit
  fi
  else
    echo "Invalid option, choose again"
  fi
done
