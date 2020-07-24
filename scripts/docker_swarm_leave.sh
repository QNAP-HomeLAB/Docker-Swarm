#!/bin/bash
# Load config variables from file
  source /share/docker/scripts/bash-colors.env
  source /share/docker/swarm/swarm_vars.env

# Help message for script
helpFunction(){
  echo -e "[-> ${blu}This script leaves a Docker Swarm environment and removes a list of stacks on QNAP Container Station architecture.${def}"
  echo
  echo -e "SYNTAX: # dwlv"
  echo -e "SYNTAX: # dwlv ${CYN}-option${def}"
  echo -e "  VALID OPTIONS:"
  echo -e "        ${CYN}-all${def}          Removes all stacks with a corresponding folder inside the '${YLW}${swarm_configs}/${def}' path, then laves the Docker Swarm."
  echo -e "        ${CYN}-noremove${def}     Does *NOT* remove any currently deployed stacks, but still leaves the swarm"
  echo -e "        ${CYN}-h${def} || ${CYN}-help${def}   Displays this help message."
  echo
  exit 1 # Exit script after printing help
  }

# Command header
  echo -e "${blu}[-> DOCKER SWARM LEAVE SCRIPT <-]${def}"

# Check for '-noremove' command options
  if [[ "$1" = "-noremove" ]] ; then
    input=no;
  elif [[ $1 = "-all" ]] ; then
    input=yes;
  elif [[ $1 = "-h" ]] || [[ $1 = "-help" ]] ; then
    helpFunction
  else
    # Query if all stacks should be removed before leaving swarm
    printf " Do you want to remove all Docker Swarm stacks (${YLW}highly recommended${def})? "; read -r -p " [(Y)es/(N)o] " input
    echo
  fi

# Remove stacks if input is Yes
  case $input in
    [yY][eE][sS]|[yY])
      # Query if all stacks should be removed before leaving swarm
      printf " Are you certain you want all Docker Swarm stacks ${RED}removed${def}? "; read -r -p " [(Y)es/(N)o] " confirm
      echo
      case $confirm in 
        [yY][eE][sS]|[yY])
        # remove all services in docker swarm
        . ${docker_scripts}/docker_stack_remove.sh -all
        ;;
        *)
        exit 1
      esac
      ;;
    [nN][oO]|[nN])
      echo -e " >> ${YLW}DOCKER SWARM STACKS WILL NOT BE REMOVED${DEF} << "
      # Pruning the system is optional but recommended
        . ${docker_scripts}/docker_system_prune.sh -f
      ;;
    *) echo -e "${YLW}INVALID INPUT:${def} Must be any case-insensitive variation of `(Y)es` or `(N)o`."; break ;;
  esac

# Leave the swarm
  docker swarm leave -f

  echo
  echo -e "${GRN}[-- DOCKER SWARM LEAVE SCRIPT COMPLETE --]${DEF}"
  echo