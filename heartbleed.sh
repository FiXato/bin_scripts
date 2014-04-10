#!/bin/bash
# Heartbleed Assistant
# (c) 2014, Filip H.F. Slagter, FiXato Software Development


PS3="Your choice: "
bold=`tput bold`
normal=`tput sgr0`
standout=`tput smso`
standoutoff=`tput rmso`
red=`tput setaf 1`
green=`tput setaf 2`

LATEST_OPENSSL_VERSION='1.0.1g'
RBENV_RUBY_VERSION=`rbenv version-name || ruby --version`
CHOICES[0]="exit"
CHOICE_TEXTS+=("(Q)uit")
CHOICES[1]="list_affected_open_files"
CHOICE_TEXTS+=("List open files matching non-${LATEST_OPENSSL_VERSION} OpenSSL")
CHOICES[2]="detect_current_ruby"
CHOICE_TEXTS+=("Check OpenSSL version for current Ruby ($RBENV_RUBY_VERSION)")
CHOICES[3]="brew_install_latest_openssl"
CHOICE_TEXTS+=("Install the latest OpenSSL via Homebrew (OSX)")
CHOICES[4]="brew_upgrade_latest_openssl"
CHOICE_TEXTS+=("Upgrade to the latest OpenSSL via Homebrew (OSX)")
CHOICES[5]="reinstall_current_rbenv_ruby"
CHOICE_TEXTS+=("Reinstalls current Ruby version ($RBENV_RUBY_VERSION) using rbenv")
CHOICES_MAX_INDEX=$((${#CHOICES[@]}-1))

MENU_CHOICES=""
for K in "${!CHOICES[@]}"; do
  MENU_CHOICES+="
    Option ($K) ${CHOICE_TEXTS[$K]}"
done

define(){ IFS='\n' read -r -d '' ${1} || true; }

define MENU_TEXT <<EOF
============================================================
Heartbleed Assistant
------------------------------------------------------------
  Please enter your choice:
    ${MENU_CHOICES}
------------------------------------------------------------
EOF


list_affected_open_files () {
  cmd="lsof | grep openssl | grep -v '${LATEST_OPENSSL_VERSION}'"
  echo "Listing open files running matching any openssl that isn't ${LATEST_OPENSSL_VERSION}:"
  echo " $bold  $cmd $normal"
  eval $cmd && echo '=Done=' || echo '=No matches='
  echo ""
}

detect_current_ruby () {
  cmd="ruby -ropenssl -e 'puts OpenSSL::OPENSSL_VERSION'"
  echo "Checking which version of OpenSSL your current Ruby (`ruby --version`) is compiled against:"
  echo " $bold  $cmd $normal"
  echo ""
  result=$(eval $cmd || echo '=Command Failed=')
  echo $bold $result $normal
  echo ""
  if [[ $result == *1.0.1g* ]]; then
    echo "${green}You seem to be using ${LATEST_OPENSSL_VERSION}, which should be unaffected o/${normal}"
  else
    echo "${standout}${red}${bold}OpenSSL ${LATEST_OPENSSL_VERSION} not detected in output.${standoutoff} You might be at risk.${normal}"
  fi
  
  echo ""
}

reinstall_current_rbenv_ruby () {
  version=`rbenv version-name`
  cmd="rbenv install -f $version"
  echo "Press any key to force a (re-)install of Ruby-$version:"
  echo " $bold  $cmd $normal"
  read -rsn1
  eval $cmd || echo '=Command Failed='
  echo ""
}

brew_install_latest_openssl () {
  cmd="brew update && brew install openssl"
  echo "Press any key to update Homebrew repo and install latest OpenSSL:"
  echo " $bold  $cmd $normal"
  read -rsn1
  eval $cmd || echo '=Command Failed='
  echo ""
}

brew_upgrade_latest_openssl () {
  cmd="brew update && brew upgrade openssl"
  echo "Press any key to update Homebrew repo and upgrade to latest OpenSSL:"
  echo " $bold  $cmd $normal"
  read -rsn1
  eval $cmd || echo '=Command Failed='
  echo ""
}

process_choice () {
  re="^[qQ0-$CHOICES_MAX_INDEX]$"
  if [ -n "$MENU_CHOICE" ]; then
    if [[ $MENU_CHOICE =~ $re ]]; then
      echo "    You picked:"
      echo "      ${MENU_CHOICE}) ${CHOICE_TEXTS[${MENU_CHOICE}]}"
      echo "------------------------------------------------------------"
      echo ""
      ${CHOICES[$MENU_CHOICE]}
    else
      echo "    Unknown option"
    fi
    unset MENU_CHOICE
  fi
}


clear
echo "This script will help you detect heartbleed."
while :
do
  echo "$MENU_TEXT"
  read -rsn1 MENU_CHOICE

  process_choice

  echo "Press any key to continue"
  read -rsn1
  unset REPLY
  clear
done