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
append_file /root/.bashrc "unalias -a"

clear
echo "Aliases have been removed"

if [ "$EUID" -ne 0 ]
then
	echo "Please run as root"
	exit
fi

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
	echo "3. End Script"
	read -p "> " task
done
