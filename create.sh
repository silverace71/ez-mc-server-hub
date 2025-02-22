#!/bin/bash

echo "This script will install a Minecraft server on your system. Do you wish to continue? (y/n)?"
read r0
if [[ $r0 =~ ^[Yy]$ ]]; then

echo "Do you agree to the minecraft EULA? (y/n)"
read r4
if [[ $r4 =~ ^[Yy]$ ]]; then
    sleep 1
else
    clear
    echo "You must agree to the minecraft EULA to continue. Exiting."
    exit
fi

## Install some dependencies

echo "Updating and installing dependencies..."
sleep 1
sudo apt update && sudo apt-get full-upgrade -y
sudo apt install git -y
if ! command -v java &> /dev/null || [[ $(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F. '{print $1}') -lt 21 ]]; then
    echo "The latest version of Java is required. Would you like to install it? (y/n)"
    read r1
    if [[ $r1 =~ ^[Yy]$ ]]; then
    sudo apt remove default-jdk openjdk* -y
    sudo apt autoremove -y
    sudo apt update
    sudo apt install openjdk-21-jdk -y
    echo "Java 21 has been installed and set as default."
    else
        echo "Java 21 or higher is already installed."
fi
if ! command -v mrpack-install &> /dev/null; then

# I would love if I could just grab the latest version of mrpack-install but they made the file extensions non-exsistent.

    wget https://github.com/nothub/mrpack-install/releases/download/v0.18.2-beta/mrpack-install_0.18.2-beta_linux_amd64.deb
    sudo dpkg -i mrpack-install_0.18.2-beta_linux_amd64.deb
    rm mrpack-install_0.18.2-beta_linux_amd64.deb
fi

# If user wants to install a modpack they can enter the link here

clear
echo "Do you want to install a modpack from modrinth? (y/n)"
read r2
if [[ $r2 =~ ^[Yy]$ ]]; then

echo "when you enter the modpack link it will extract the mod name and version for you"
sleep 1
echo "please enter the link in this format"
echo "https://modrinth.com/modpack/fabulously-optimized/version/6.4.0-alpha.6"
echo "https://modrinth.com/modpack/(modpack name)/version/(version number)"
echo "(go onto modrinth and click on the modpack and then click on the version tab and copy the link for your modpack choice)"

while true; do
    read -p "Enter the modpack link: " link

    # Extracting the mod name and version
    mod_name=$(echo $link | grep -oP '(?<=/modpack/)[^/]+')
    version=$(echo $link | grep -oP '(?<=/version/)[^ ]+')

    echo "Mod Name: $mod_name"
    echo "Version: $version"
    echo "Is this correct? (y/n)"
    read r3
    if [[ $r3 =~ ^[Yy]$ ]]; then
        break
    else
        echo "Please enter the modpack link again."
        continue
    fi
done

read -p "Enter the server directory (default: fabric-srv): " server_dir
server_dir=${server_dir:-fabric-srv}  # Default to fabric-srv if empty

mrpack-install $mod_name $version --server-dir $server_dir --server-file srv.jar

# Same as custom server setup but just with the modpack already installed
# adding the ram and thread allocation section

echo "Modpack installation complete, starting system configuration."
sleep 1
wget https://raw.githubusercontent.com/silverace71/QuickMCServer/main/systemconfig.sh
sudo chmod +x systemconfig.sh
./systemconfig.sh
else
echo "continuing without modpack installation. Moving on to custom server setup."

## This is the setup for the minecraft server if you want to start fresh and make your own modpack or just want vanilla

## Download section
echo "Choose a Minecraft server flavor to install:"
echo "1. Vanilla"
echo "2. Fabric"
echo "3. Quilt"
echo "4. Forge"
echo "5. Neoforge"
echo "6. Paper"
read -p "Enter your choice (1-6): " flavor_choice

attempts=0
while true; do
    case $flavor_choice in
        1) flavor="vanilla"; break ;;
        2) flavor="fabric"; break ;;
        3) flavor="quilt"; break ;;
        4) flavor="forge"; break ;;
        5) flavor="neoforge"; break ;;
        6) flavor="paper"; break ;;
        *) 
            attempts=$((attempts + 1))
            if [ $attempts -eq 3 ]; then
                echo "Invalid choice. Exiting."; exit 1
            else
                echo "Invalid choice. Please try again."
                read -p "Enter your choice (1-6): " flavor_choice
            fi
            ;;
    esac
done

echo "Hit the enter key to load default values when prompted"
sleep 2

# Get additional parameters for the installation
read -p "Enter the server directory (default: fabric-srv): " server_dir
server_dir=${server_dir:-fabric-srv}  # Default to fabric-srv if empty

read -p "Enter the Minecraft version (default: latest): " mc_version
mc_version=${mc_version:-latest}  # Default to latest if empty

# Execute the installation command
mrpack-install server $flavor --server-dir $server_dir --minecraft-version $mc_version --server-file srv.jar

## System configuration section

wget https://raw.githubusercontent.com/silverace71/QuickMCServer/main/systemconfig.sh
sudo chmod +x systemconfig.sh
./systemconfig.sh

fi

# Start the server to generate files

echo "Starting the server to generate files..."
java -jar $jvm_args srv.jar nogui &  # Run in the background
server_pid=$!  # Capture the PID of the server process

# Wait for server.properties to generate
while [ ! -f "server.properties" ]; do
    sleep 1  # Check every second
done

echo "Stopping the server..."
# Send the stop command to the server
echo "stop" | java -jar $jvm_args srv.jar nogui
wait $server_pid  # Wait for the server process to exit
echo "Updating server.properties..."
if [ -f "server.properties" ]; then
    # Update the port
    sed -i "s/^server-port=.*/server-port=$port/" server.properties
    # Update the view distance
    sed -i "s/^view-distance=.*/view-distance=$vdist/" server.properties
else
    echo "server.properties file not found!"
fi

echo "Use ./start.sh to start the server!"

else
echo "install cancelled"
exit
fi
else
echo "install cancelled"
exit
fi