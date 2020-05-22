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

while [ true ]
do
  echo "Choose a task"
  echo "1. End Script"
  read -p "> " task
  if [ $task = "1" ]
  then
    exit
  fi
  else
    echo "Invalid option, choose again"
  fi
done
