#!/bin/bash
#Author: Pastafarista

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

COLUMNS=$(tput cols)
space=$(($COLUMNS/2 - 29))

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Exiting...\n${endColour}"
	tput cnorm
	exit 1
}

function title() {
  termwidth="$(tput cols)"
  padding="$(printf '%0.1s' ={1..500})"
  printf '%*.*s %s %*.*s\n' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

function center(){
  cont=0
  while [ $cont -le $space ];do
    echo -n " "
    let cont+=1
  done
  string1=$(echo -e "$1" | awk '{print $1}' | tr "_" " ")
  echo -n "$string1"
  cont=0 
  string2=$(echo -e "$1" | awk '{print $2}')
  reps=$((60-${#string1}))
  while [ $cont -le $reps ];do 
    echo -n " "
    let cont+=1
  done
  echo "$string2" | tr "_" " "
  


}

#Global variables
steam_info="https://steamid.uk/profile/"
faceit_info="https://faceitfinder.com/profile/"

if [ $(echo $1 | grep "https://steam")==$1 ];then 
  id=$(echo $1 | tr " " "/" | awk 'NF{print $NF}') 
else 
  id=$1
fi
echo $id
w3m -dump "https://steamid.uk/profile/$1" > steam_data.tmp 2>&1
community_id=$(grep "Community ID:" steam_data.tmp | awk 'NF{print $NF}') 
wget -O profile.tmp "https://faceitfinder.com/es/profile/$community_id" > /dev/null 2>&1 

#Player info 
current_alias=$(grep "steam account avatar" steam_data.tmp | awk '{print $id}')
account_status=$(grep "Account status:" profile.tmp | tr "<>" "  " | awk '{print $17}')
plays_csgo_since=$(grep "Plays CS:GO since:" profile.tmp | tr "<>" "  " | awk '{print $17}'| tr "." "/")
total_hours=$(grep "CS:GO total hours:" profile.tmp | tr "<>" "  " | awk '{print $22}')
hours_last_2_weeks=$(grep "CS:GO last 2 weeks hours:" profile.tmp | tr "<>" "  " | awk '{print $24}')
banned_friends=$(grep "Banned friends:" profile.tmp | tr "<>" "  " | awk '{print $17}')
banned_friends_percentage=$(grep "Banned friends:" profile.tmp | tr "<>" "  " | awk '{print $18}' | tr -d "()")
faceit_innactive=$false

#FACEIT 
if [ -z $(grep "account-faceit-notfound" profile.tmp) ]
then
  faceit_innactive=$true
  faceit_elo=$(grep "ELO:" profile.tmp | tr "<>" "  " | awk '{print $7}') 
  faceit_lvl=$(grep "FaceIt level" profile.tmp | tr "<>__" "    " | awk '{print $14}')
  faceit_matches=$(grep "Matches:" profile.tmp | tr "<>" "  " | awk '{print $7}') 
  faceit_KD=$(grep "K/D:" profile.tmp | tr "<>" "  " | awk '{print $7}')
  faceit_WR=$(grep "Winrt:" profile.tmp | tr "<>" "  " | awk '{print $7}')
  #Teamates
  wget -O teammates.tmp "https://faceitfinder.com/stats/$community_id/teammates" > /dev/null 2>&1 
  teammate_names=$(sed -n '87,246 p' teammates.tmp | grep avatar | tr "<>" "  "  | awk '{print $18}' | sed s/alt=//)

  teammates_img=$(sed -n '87,246 p' teammates.tmp | grep avatar | tr "<>" "  "  | awk '{print $15}' | sed 's/src=//' | tr -d '"') 

  teammates_id=$(sed -n '87,246 p' teammates.tmp | grep avatar | tr "<>" "  "  | awk '{print $10}' | sed 's/href=//' | tr -d '"/' | sed 's/stats//')

fi

#Render
title $current_alias

grep "Steam profile image" profile.tmp | awk '{print $7}' | sed 's/src=//' | xargs kitty +kitten icat 2>/dev/null
center "${blueColour}Name:${endColour}  ${purpleColour}$current_alias${endColour}"
if [ $account_status == 'Public' ];then
  color=$greenColour
else
  color=$redColour
fi 
center "${blueColour}Account_Status:${endColour}  ${color}$account_status${endColour}"
center "${blueColour}Plays_CSGO_since:${endColour}  $plays_csgo_since"
center "${blueColour}CSGO_hours_in_the_last_2_weeks:${endColour}  $hours_last_2_weeks"
center "${blueColour}Banned_friends:${endColour}  $banned_friends"_"${redColour}$banned_friends_percentage${endColour}"

if [ $faceit_innactive ]
then
  echo "${redColour}Faceit account not found${endColour}"
else
  #Render Faceit stats
  echo 
  color=$grayColour
  if [[ $faceit_lvl -ge 3 && $faceit_lvl -lt 4 ]]
  then
    color=$greenColour
  elif [[ $faceit_lvl -ge 7 && $faceit_lvl -lt 8 ]]
  then
    color=$yellowColour
  elif [[ $faceit_lvl -ge 9 && $faceit_lvl -lt 10 ]]
  then
    color=$purpleColour
  elif [[ $faceit_lvl -ge 10 ]]
  then
    color=$redColour
  fi
  
  center "${blueColour}Faceit_lvl:${endColour} ${color}$faceit_lvl${endColour}"
  center "${blueColour}Faceit_elo:${endColour} $faceit_elo"
  center "${blueColour}Faceit_matches:${endColour} $faceit_matches"
  if [ $(echo $faceit_KD | tr "." " " | awk '{print $1}') -ge 1 ]
  then
    color=$greenColour
  else
    color=$redColour
  fi

  center "${blueColour}Faceit_KD:${endColour} ${color}$faceit_KD${endColour}"
  if [  $(echo $faceit_WR | tr "." " " | awk '{print $1}') -ge 50 ];then
    color=$greenColour
  else 
    color=$redColour 
  fi 
  center "${blueColour}Faceit_winrate:${endColour} ${color}$faceit_WR${endColour}"
  #Faceit teammates
  title "$current_alias's teammates"
  for i in {1..5};do
    teammate_name=$(echo -e $teammate_names | tr -d '"'| awk -v temp="${i}" '{print $temp}')
    teammate_id=$(echo -e $teammates_id | awk -v temp="${i}" '{print $temp}') 
    wget -O teammate_steam.tmp https://steamcommunity.com/profiles/$teammate_id > /dev/null 2>&1
    teammate_img=$(grep 'avatars' teammate_steam.tmp | grep '_full.jpg' | awk 'NF{print $NF}' | sed 's/href=//' | sed 's/src=//' | tr -d '">' | tr "\n" " " | awk '{print $1}' 2>/dev/null)
    teammate_lvl=$(w3m -dump https://faceitfinder.com/en/profile/$teammate_id | grep 'FaceIt level' | awk '{print $3}')
    echo
    kitty +kitten icat $teammate_img
    center "${blueColour}Name:${endColour} ${purpleColour}$teammate_name${endColour}"
    if [[ $teammate_lvl -ge 1 && $teammate_lvl -lt 4 ]]
    then
      color=$greenColour
    elif [[ $teammate_lvl -ge 4 && $teammate_lvl -lt 8 ]]
    then
      color=$yellowColour
    elif [[ $teammate_lvl -ge 8 && $teammate_lvl -lt 10 ]]
    then
      color=$purpleColour
    elif [[ $teammate_lvl -ge 10 ]]
    then
      color=$redColour
    fi
    center "${blueColour}Faceit_lvl:${endColour} ${color}$teammate_lvl${endColour}"
  done
fi

