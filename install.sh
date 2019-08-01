#!/bin/bash

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=6
BACKTITLE="Elitium Staking Masternode Setup"
TITLE="Elitium Staking Masternode Setup"
MENU="Please select one of the following options:"

OPTIONS=(1 "Install fresh Masternode"
         2 "Update Masternode wallet"
         3 "Start Masternode"
	     4 "Stop Masternode"
	     5 "Check Masternode status"
	     6 "Rebuild Masternode")

CHOICE=$(whiptail --clear\
		          --backtitle "$BACKTITLE" \
                  --title "$TITLE" \
                  --menu "$MENU" \
                  $HEIGHT $WIDTH $CHOICE_HEIGHT \
                  "${OPTIONS[@]}" \
                  2>&1 >/dev/tty)

clear
case $CHOICE in
         1)
            echo Starting the installation process...
echo Checking and installing VPS dependencies, please wait...
echo -e "Checking memory available, creating swap space if nescecary."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
SWAP=$(swapon -s)
if [[ "$PHYMEM" -lt "2" && -z "$SWAP" ]];
  then
    echo -e "${GREEN}VPS has less than 2G of RAM available, creating swap space.${NC}"
    dd if=/dev/zero of=/swapfile bs=1024 count=2M
    chmod 600 /swapfile
    mkswap /swapfile
    swapon -a /swapfile
else
  echo -e "${GREEN}VPS has atleast 2G of RAM available.${NC}"
fi
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}VPS is not running Ubuntu 16.04. Not compatible.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 Installation must be run as root.${NC}"
   exit 1
fi
clear
sudo apt update
sudo apt-get -y upgrade
sudo apt-get install git -y
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils -y
sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
sudo apt-get install libssl-dev libevent-dev libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y
sudo apt-get install libqt4-dev libprotobuf-dev protobuf-compiler -y
clear
echo VPS dependencies are now installed.
echo Creating and setting up VPS firewall...
sudo apt-get install -y ufw
sudo ufw allow 55606
sudo ufw allow 22
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw logging on
echo "y" | sudo ufw enable
sudo ufw status
echo VPS firewall setup is completed.
echo "Downloading eums Wallet (v2.0.4)..."
wget https://github.com/eumsproject/eums-core/releases/download/1.1.4/eums-1.1.4-x86_64-linux-gnu.tar.gz
tar -xvf eums-1.1.4-x86_64-linux-gnu.tar.gz
chmod +x eums-1.1.4/bin/eumsd
chmod +x eums-1.1.4/bin/eums-cli
sudo cp eums-1.1.4/bin/eumsd /usr/bin/eumsd
sudo cp eums-1.1.4/bin/eums-cli /usr/bin/eums-cli
sudo rm -rf eums-1.1.4-x86_64-linux-gnu.tar.gz
echo eums Wallet successfully installed.
clear
echo Configuring eums Wallet configuration...
RPCUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
EXTIP=`curl -s4 icanhazip.com`
echo "Please enter your Masternode Privatekey (masternode genkey):"
read GENKEY
mkdir -p /root/.eums && touch /root/.eums/eums.conf
cat << EOF > /root/.eums/eums.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
server=1
listen=1
daemon=1
staking=1
rpcallowip=127.0.0.1
rpcport=19656
port=19655
logtimestamps=1
maxconnections=256
masternode=1
externalip=$EXTIP
masternodeprivkey=$GENKEY
EOF
clear
eumsd
echo eums Wallet has been successfully configured and started.
echo If you get a message asking to rebuild the database, run eumsd -reindex
echo If you still have further issues please reach out a member in our Discord channel. 
echo Ensure you use this Masternode Private Key on your Windows Wallet: $GENKEY
            ;;
	    
    
         2)
sudo eums-cli stop
echo "! Stopping eums Wallet !"
echo Configuring VPS firewall...
sudo apt-get install -y ufw
sudo ufw allow 55606
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw logging on
echo "y" | sudo ufw enable
sudo ufw status
echo VPS firewall configured.
echo "Downloading eums Wallet (v1.1.4)..."
wget https://github.com/eumsproject/eums-core/releases/download/1.1.4/eums-1.1.4-x86_64-linux-gnu.tar.gz
echo Updating eums Wallet...
tar -xvf eums-1.1.4-x86_64-linux-gnu.tar.gz
chmod +x eums-1.1.4/bin/eumsd
chmod +x eums-1.1.4/bin/eums-cli
sudo cp eums-1.1.4/bin/eumsd /usr/bin/eumsd
sudo cp eums-1.1.4/bin/eums-cli /usr/bin/eums-cli
sudo rm -rf eums-1.1.4-x86_64-linux-gnu.tar.gz
eumsd
echo eums Wallet update complete. 
            ;;
         3)
            eumsd
            ;;
         4)
            eums-cli stop
            ;;
	     5)
	        eums-cli masternode status
	        ;;
         6)
	        eumsd -reindex
            ;;
esac

