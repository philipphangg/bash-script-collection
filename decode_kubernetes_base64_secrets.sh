#!/bin/bash

# This script is intended to be used in repositories with kubernetes-secret.yml files as make target :
#    show-kubernetes-secrets:
#       tools/decode_kubernetes_base64_secrets.sh -f "openshift/*-secrets.yml"
#
# The script parses and decodes all kubernetes-base64-secrets from given files -
# But the secret key has to be all upper case : 
#     data:
#       MYSQL_USER: chjlllucGFsYXBp
#       MYSQL_PASSWORD: TkpVSUhsdDDDopdlamZoSklz
#
# For file-path and file-name "*" can be used as wildcard. Example: "openshift/*-secrets.yml".

# default for secret files
SECRET_FILES="openshift/*-secrets.yml"

while getopts ":hf:" OPTION; do
  case ${OPTION} in
    f)
      SECRET_FILES=$OPTARG
      ;;
    h|?)
      echo "Usage:"
      echo "  decode_okd_base64_secrets.sh -h                              Display this help message."
      echo "  decode_okd_base64_secrets.sh -f "openshift/*-secrets.yml"    Parse and decode all secrets from *-sercrets.yml files within openshift/."
      exit 0
      ;;
  esac
done
shift $((OPTIND -1))


BOLD=$(tput bold)
SMUL=$(tput smul)
RED=$(tput setaf 1)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
NC=$(tput sgr0)

echo "${RED}${BOLD}${SMUL}Show secrets in $SECRET_FILES${NC}"
echo ""

for FILE in $SECRET_FILES
do
    echo "${RED}${BOLD}${SMUL}Secrets from file $FILE:${NC}"

    while read -a LINE_ARRAY; do
        LINE_FIRST_PART=${LINE_ARRAY[@]:0:1}

        if [ ${LINE_FIRST_PART^^} == $LINE_FIRST_PART ] && [[ $LINE_FIRST_PART == *: ]] ; then
            LINE_SECOND_PART=${LINE_ARRAY[@]:1:2}
            echo -n "${MAGENTA}$LINE_FIRST_PART "
            echo "${CYAN}$(echo -n "$LINE_SECOND_PART" | base64 --decode) ${NC}"
        fi
    done  < "$FILE"

    echo ""
done
