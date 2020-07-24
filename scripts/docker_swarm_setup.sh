#!/bin/bash
# Load config variables from file
  source /share/docker/scripts/bash-colors.env
  source /share/docker/swarm/swarm_vars.env

# Help message for script
helpFunction(){
  echo -e "${blu}[-> This script performs Docker Swarm initialization tasks on QNAP Container Station architecture. <-]${DEF}"
  echo
  echo -e " SYNTAX: # dwinit"
  echo -e " SYNTAX: # dwinit -${cyn}option${DEF}"
  echo -e "   VALID OPTIONS:"
  echo -e "     -${cyn}all${DEF}      Creates the Docker Swarm, then deploys all stacks with a corresponding folder inside the '${YLW}${swarm_configs}/${DEF}' path."
  echo -e "     -${cyn}listed${DEF}   Creates the Docker Swarm, then deploys the 'listed' array of stacks defined in '${YLW}${swarm_configs}/${cyn}swarm_stacks.conf${DEF}'"
  echo -e "     -${cyn}default${DEF}  Creates the Docker Swarm, then deploys the 'default' array of stacks defined in '${YLW}${swarm_configs}/${cyn}swarm_stacks.conf${DEF}'"
  echo -e "     -${cyn}help${DEF}     Displays this help message."
  echo
  exit 1 # Exit script after printing help
  }

# Stack deployment confirmation query
  if [[ "$1" = "-h" ]] || [[ "$1" = "-help" ]] ; then helpFunction;
  elif [[ -z "$1" ]] || [[ "$1" = "" ]] ; then
    printf "Do you want to deploy the '-${cyn}default${DEF}' list of Docker Swarm stacks?"; read -r -p " [(Y)es/(N)o] " input
    case $input in 
      [yY]|[yY][eE][sS]) ;;
      [nN]|[nN][oO])
        # Query if Traefik should still be deployed
        printf " - Should ${cyn}traefik${DEF} still be installed (${YLW}recommended${DEF})?"; read -r -p " [(Y)es/(N)o] " confirm
        case $input in 
          [yY]|[yY][eE][sS]) ;;
          [nN]|[nN][oO]) ;;
          *) echo -e "${YLW}INVALID INPUT${DEF}: Must be any case-insensitive variation of 'yes' or 'no'."; break ;;
        esac
        ;;
      *) echo -e "${YLW}INVALID INPUT${DEF}: Must be any case-insensitive variation of 'yes' or 'no'."; break ;;
    esac
    echo
  else helpFunction;
  fi

# Command header
  echo -e "${blu}[-> DOCKER SWARM INITIALIZATION SCRIPT <-]${DEF}"

# Swarm folder creation
  if [[ ! -f "${docker_folder}/{scripts,secrets,swarm,compose}" ]]; then
    mkdir -pm 600 "${docker_folder}"/{scripts,secrets,swarm/{appdata,configs},compose/{appdata,configs}};
    # setfacl -Rdm g:dockuser:rwx "${docker_folder}";
    # chmod -R 600 "${docker_folder}";
  fi

# Swarm initialization
  #echo -e " -> INITIALIZING SWARM <- "
  docker swarm init --advertise-addr "${var_nas_ip}"
  # Pause until swarm is initialized
  while [ ! "$(docker stack ls)" = "NAME                SERVICES" ]; 
  do sleep 1; done
  echo -e " -- ${grn}SWARM INITIALIZED${DEF} -- "
  echo

# Traefik overlay network creation
  echo -e " -> CREATING ${cyn}traefik_public${DEF} OVERLAY NETWORK <- "
  docker network create --driver=overlay --subnet=172.1.1.0/22 --attachable traefik_public
  while [ "$(docker network ls --filter name=traefik -q)" = "" ];
  do sleep 1; done
  echo -e " -- ${cyn}traefik_public${DEF} OVERLAY NETWORK ${GRN}CREATED${DEF} -- "
  echo
  # Required networks creation verification
  if [ "$(docker network ls --filter name=traefik -q)" = "" ] || [ "$(docker network ls --filter name=gwbridge -q)" = "" ]; then
    docker network ls
    echo
    echo -e " >> THE ABOVE LIST MUST INCLUDE THE '${cyn}docker_gwbridge${DEF}' AND '${cyn}traefik_public${DEF}' NETWORKS"
    echo -e " >> IF EITHER OF THOSE NETWORKS ARE NOT LISTED, YOU MUST LEAVE, THEN RE-INITIALIZE THE SWARM"
    echo -e " >> IF YOU HAVE ALREADY ATTEMPTED TO RE-INITIALIZE, ASK FOR HELP HERE: ${mgn} https://discord.gg/KekSYUE ${def}"
    echo
    echo -e " >> ${YLW}DOCKER SWARM STACKS WILL NOT BE DEPLOYED${DEF} << "
    echo
    echo -e " -- ${RED}ERROR${DEF}: DOCKER SWARM SETUP WAS ${YLW}NOT SUCCESSFUL${DEF} -- "
    exit 1 # Exit script here
  fi

# Stack deployment
  if [[ "$1" = "" ]]; then
    case "${input}" in
      [yY]|[yY][eE][sS])
        . "${docker_scripts}"/docker_stack_deploy.sh -default
        ;;
      [nN]|[nN][oO])
        case "${confirm}" in 
          [yY]|[yY][eE][sS])
            . "${docker_scripts}"/docker_stack_deploy.sh traefik
          ;;
          *) echo -e " >> ${YLW}DOCKER SWARM STACKS WILL NOT BE DEPLOYED${DEF} << " ;;
        esac
        ;;
    esac
  elif [[ $1 = "" ]] || [[ $1 = "-h" ]] || [[ $1 = "-help" ]] || [[ $1 = "--help" ]] ; then
    helpFunction
  else
    . "${docker_scripts}"/docker_stack_deploy.sh "$1"
  fi

# Script completion message
  # echo
  echo -e "${GRN}[-- DOCKER SWARM SETUP SCRIPT COMPLETE --]${DEF}"
  echo