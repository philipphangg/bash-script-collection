#!/bin/bash

#
# Name:          Search and modify ldap
# Description:   Script for easy updating of multiple ldap entries by search reference
# Author:        Philipp Hangg
# Mail:          info@hangg.com
#

# LDAP Config
BIND_DN="cn=example-admin,ou=people,dc=example,dc=org"
BIND_HOST="ldap://openldap.example.org"
BIND_PASSWORD="top_secret"

SEARCH_FILTER="(&(!(mail=example-admin@example.org))(sn=Smith))"
SEARCH_BASE="ou=people,dc=example,dc=org"

# LDIF for ldapmodify - first part with dn will be added by script after search (dn: cn=modifyme,ou=people,dc=example,dc=org)
# 
#  
#  changetype: modify
#  replace: mail
#  mail: modme@example.org
#  -
#  add: title
#  title: PalimPalim
#  -
#  add: jpegPhoto
#  jpegPhoto:< file:///tmp/modme.jpeg
#  -
#  delete: description
#  -
MODIFY_LDIF_PART="changetype: modify\nadd: title\nctitle: PalimPalim"


SEARCH_ATTRIBUTES="dn"
NOW_STRING=$(date +'%Y-%m-%d-%H-%M-%S')
SEARCH_SIMULATION=false

BOLD=$(tput bold)
SMUL=$(tput smul)
RED=$(tput setaf 1)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
NC=$(tput sgr0)

while getopts ":hF:B:D:H:M:S" OPTION; 
do
  case ${OPTION} in
    F)
      SEARCH_FILTER=$OPTARG
      ;;
    B)
      SEARCH_BASE=$OPTARG
      ;;
    D)
      BIND_DN=$OPTARG
      ;;
    H)
      BIND_HOST=$OPTARG
      ;;
    M)
      MODIFY_LDIF_PART=$OPTARG
      ;;
    S)
      SEARCH_SIMULATION=true
      ;;
    h|?)
      printf "USAGE:\n"
      printf "     search_and_modify_ldap.sh [-F ldap_filter] [-B search_base] [-D bind_dn] [-H bind_host] [-M modify_ldif_part] [-S]\n"
      exit 0
      ;;
  esac
done
shift $((OPTIND -1))

read -s -p "Enter password for bind with $BIND_DN: " BIND_PASSWORD
printf "\n"

# Search for entries with SEARCH_FILTER
FOUND_ENTRIES=$(ldapsearch -LLL -o ldif-wrap=no -D $BIND_DN -w $BIND_PASSWORD -H $BIND_HOST -b $SEARCH_BASE $SEARCH_FILTER $SEARCH_ATTRIBUTES)
if [ -z "$FOUND_ENTRIES" ]
then
  printf "Search found nothing\n"
fi

# As long as entries where found
while [ -n "$FOUND_ENTRIES" ]
do
  printf "Search found entries:\n"

  # change all found entries
  for ENTRY_DN in $FOUND_ENTRIES
  do

    if [ $ENTRY_DN != "dn:" ]
    then
      if $SEARCH_SIMULATION;
      then
        printf "Entry that would have been modified: $ENTRY_DN \n"
      else  
        printf "dn: $ENTRY_DN\n$MODIFY_LDIF_PART" | ldapmodify -D $BIND_DN -H $BIND_HOST -x -w $BIND_PASSWORD | tee -a modified_entries_$NOW_STRING.txt
      fi
    fi

  done

  # Search another time, because on first search limit could be exceeded
  FOUND_ENTRIES=$(ldapsearch -LLL -o ldif-wrap=no -z $SIZE_LIMIT -D $BIND_DN -w $BIND_PASSWORD -H $BIND_HOST -b $SEARCH_BASE $SEARCH_FILTER $SEARCH_ATTRIBUTES)
  if [ -z "$FOUND_ENTRIES"]
  then
    printf "Last search found nothing - All entries where changed\n"
  fi

done
