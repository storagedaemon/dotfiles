##############################
# .bashrc by Violet Rodriguez ############################
#                                                        #
# Prompt:                                                #
# [hostname] (pwd) >>>                                   #
#                  |||                                   #
#                  ||red if user is root                 #
#                  |red if login session is root         #
#                  always the host color                 #
#                                                        #
# Functions:                                             #
# showhost() - show the [hostname] portion               #
# hidehost() - hide the [hostname] portion               #
# sethost(string name) - set the value inside [hostname] #
#                                                        #
# showline() - print a separator line above the prompt   #
# hideline() - do not print separator line               #
# sethc(int color) - sets the color of the '>' symbols   #
# aurget(string name) - fetches a package from the AUR   #
#                                                        #
# External Configuration File:                           #
# .bash-config - put custom functions, etc. here         #
#                                                        #
# Relatively Safe File Updater:                          #
# updatefile(string URL, string localFileName)           #
#                                                        #
##########################################################

# pretty print functions
notice() { echo -e "\e[0;34m:: \e[1;37m${*}\e[0m"; }

# placeholder functions (keeps bash from complaining loudly)
set_prompt () { :; }
custom_hook() { :; }

# === BASIC SETUP ===

# Check for an interactive session
[ -z "$PS1" ] && return

#PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\007"'
#export PROMPT_COMMAND

# Enable huge history
export HISTFILESIZE=9999999999
export HISTSIZE=9999999999

# Ignore "ls" commands
export HISTIGNORE="ls"

# Save timestamp info for every command
export HISTTIMEFORMAT="[%Y-%m-%d - %H:%M:%S] "

# Dump the history file after every command
shopt -s histappend
#export PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"

# set up autocomplete for some commands
complete -cf sudo

# set a basic prompt, just in case.
PS1='[\u@\h \W]\$ '

# adding local user's bin directory to the path
PATH=~/bin:$PATH

# I like nano, comment these for system defaults
export EDITOR="nano -w"
export VISUAL="nano -w"

# make the window resize properly
shopt -s checkwinsize

# set up custom configuration stuffs
CONFIGFILE="${HOME}/.bash-config"

if [ -f ${CONFIGFILE} ]; then
    . ${CONFIGFILE}
else        # config file doesn't exist, so create it
    touch ${CONFIGFILE}
    SYSTEM=$(uname -s)
    if [ "$SYSTEM" == "Linux" ]; then
        echo "# Linux system defaults" >> ${CONFIGFILE}
        echo "alias ls='ls --color=auto'" >> ${CONFIGFILE}
    elif [ "$SYSTEM" == "FreeBSD" ]; then
        echo "# FreeBSD system defaults" >> ${CONFIGFILE}
        echo "alias ls='ls -G'" >> ${CONFIGFILE}
        echo "alias md5sum='md5'" >> ${CONFIGFILE}
    fi
    if ! which nano >/dev/null 2>&1; then
        if which pico >/dev/null 2>&1; then
            echo "alias nano='pico'" >> ${CONFIGFILE}
        fi
    fi
    echo >> ${CONFIGFILE}
    echo "# This function is run at the end of the bash startup" >> ${CONFIGFILE}
    echo "unset custom_hook" >> ${CONFIGFILE}
    echo "custom_hook () { : # this colon is necessary if there's no content

}

#LINE_ENABLED=1      # Uncomment this line to enable the horizontal line above the prompt
" >> ${CONFIGFILE}

    # now that we've created this, source it!
    . ${CONFIGFILE}
fi

# === FUNCTIONS, ETC ===

GITBRANCH=""

get_git_branch () {
    GITBRANCH=$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /')
}

# this gets its own function for ease of use later
update_titlebar () {
    echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\007"
}

# line separator is disabled by default
export PROMPT_COMMAND="history -a; update_titlebar; get_git_branch;"

# highlight text in a pipeline, ex: cat file | highlight "searchstring"
highlight() {
    perl -pe "s/$1/\e[1;31;43m$&\e[0m/g"
}

# If we're on a dumb console, stop here, we don't want color and we don't want to update.
if [[ "$TERM" == "linux" ]]; then
    unset PROMPT_COMMAND
    PS1='[\u@\h \W]\$ '
    return
fi

# basic colors for bash prompt!
loadcolors () {
    txtblk='\e[0;30m' # Black - Regular
    txtred='\e[0;31m' # Red
    txtgrn='\e[0;32m' # Green
    txtylw='\e[0;33m' # Yellow
    txtblu='\e[0;34m' # Blue
    txtpur='\e[0;35m' # Purple
    txtcyn='\e[0;36m' # Cyan
    txtwht='\e[0;37m' # White
    bldblk='\e[1;30m' # Black - Bold
    bldred='\e[1;31m' # Red
    bldgrn='\e[1;32m' # Green
    bldylw='\e[1;33m' # Yellow
    bldblu='\e[1;34m' # Blue
    bldpur='\e[1;35m' # Purple
    bldcyn='\e[1;36m' # Cyan
    bldwht='\e[1;37m' # White
    unkblk='\e[4;30m' # Black - Underline
    undred='\e[4;31m' # Red
    undgrn='\e[4;32m' # Green
    undylw='\e[4;33m' # Yellow
    undblu='\e[4;34m' # Blue
    undpur='\e[4;35m' # Purple
    undcyn='\e[4;36m' # Cyan
    undwht='\e[4;37m' # White
    bakblk='\e[40m'   # Black - Background
    bakred='\e[41m'   # Red
    bakgrn='\e[42m'   # Green
    bakylw='\e[43m'   # Yellow
    bakblu='\e[44m'   # Blue
    bakpur='\e[45m'   # Purple
    bakcyn='\e[46m'   # Cyan
    bakwht='\e[47m'   # White
    txtrst='\e[0m'    # Text Reset
}

# make the colors accessible to this script
loadcolors

# default host color (the >>> section in the prompt)
PROMPT_HOSTNAME_COLOR=${txtwht}

# be sure to have some good defaults, just in case
PROMPT_HOSTNAME="\h"
PROMPT_CWD="\w"
PROMT_HOSTNAME_BOX="\[${txtwht}\][\[${txtrst}\]${PROMPT_HOSTNAME_COLOR}\[${txtwht}\]] "

# prompt commands, to change how the current working directory is displayed
long () { PROMPT_CWD="\w"; set_prompt; }
short () { PROMPT_CWD="\W"; set_prompt; }

# show or hide the hostname of the server, or change the displayed name, in that order
showhost () { PROMPT_HOSTNAME_BOX="\[${PROMPT_HOSTNAME_COLOR}\][\[${txtrst}\]${PROMPT_HOSTNAME}\[${PROMPT_HOSTNAME_COLOR}\]] ";  set_prompt; }
hidehost () { PROMPT_HOSTNAME_BOX="";  set_prompt; }
sethost () {
    if [ -z "${1}" ]; then
        PROMPT_HOSTNAME="\h"
        showhost
    else
        PROMPT_HOSTNAME="${1}"
        showhost
    fi
    set_prompt
}

# draw a line separating each command's output
draw_line () {
    # like to use a different date format?  Edit DATEFORMAT.
    # The line length will adjust automagically.
    DATEFORMAT="+%r"
    DATESTRING=$(date ${DATEFORMAT})
    DATELENGTH=${#DATESTRING}
    ((WIDTH=COLUMNS-DATELENGTH-3))
    echo -ne "${bldblk}"
    for (( c=1; c<=$WIDTH; c++ )); do echo -n "-"; done
    echo -n "|"
    echo -ne " ${DATESTRING}${txtrst}\n"
}
hideline() { export PROMPT_COMMAND="history -a; update_titlebar;"; }
showline() { export PROMPT_COMMAND="history -a; update_titlebar; draw_line;"; }


# function to set host color, accepts 256-color syntax
# ex: sethc 140
sethc ()
{
    loadcolors
    PROMPT_HOSTNAME_COLOR="\e[38;5;${1}m"
    PROMPT_HOSTNAME_BOX="\[${PROMPT_HOSTNAME_COLOR}\][\[${txtrst}\]${PROMPT_HOSTNAME}\[${PROMPT_HOSTNAME_COLOR}\]] "
}

# Try to dynamically set the hostname color based on the hostname's md5sum
if which bc >/dev/null 2>&1;
then
    sethc $(echo ${HOSTNAME} | md5sum | head -c 2 | tr a-z A-Z | xargs echo ibase=16\;  | bc)
else
    sethc $(printf "%d\n" 0x$(echo ${HOSTNAME} | md5sum | head -c 2))
fi

# Function set the prompt.
set_prompt ()
{
    if [ `id -u` == "0" ]; then
        if [ -n "${SUDO_USER}" ]; then
            PS1="${PROMPT_HOSTNAME_BOX}\[${txtwht}\](\[${txtrst}\]${PROMPT_CWD}\[${txtwht}\]) \[${PROMPT_HOSTNAME_COLOR}\]>>\[${bldred}\]>\[${txtrst}\] "
        else
            PS1="${PROMPT_HOSTNAME_BOX}\[${txtwht}\](\[${txtrst}\]${PROMPT_CWD}\[${txtwht}\]) \[${PROMPT_HOSTNAME_COLOR}\]>\[${bldred}\]>>\[${txtrst}\] "
        fi
    else
        PS1="${PROMPT_HOSTNAME_BOX}\[${txtwht}\](\[${txtrst}\]${PROMPT_CWD}\[${txtwht}\]) \${GITBRANCH}\[${PROMPT_HOSTNAME_COLOR}\]>>>\[${txtrst}\] "
    fi
}

# Actually set it here
set_prompt

# This version of the sethc function will edit the prompt color on the fly.
# It actually replaces the previous version within this script which isn't dynamic
unset sethc
sethc ()
{
    loadcolors
    PROMPT_HOSTNAME_COLOR="\e[38;5;${1}m"
    PROMPT_HOSTNAME_BOX="\[${PROMPT_HOSTNAME_COLOR}\][\[${txtrst}\]${PROMPT_HOSTNAME}\[${PROMPT_HOSTNAME_COLOR}\]] "
    set_prompt
}

# handy function to show ALL THE COLORS
showcolors () {
    echo "=== Basic Colors ==="
    loadcolors
    for X in {0..255}; do
        [ $X == 16 ] && echo && echo "=== Extended Colors ==="
        echo -e "${X}: \e[38;5;${X}m>>>${txtrst}"
    done
}

# apply any custom configuration stuff
if [[ ${LINE_ENABLED} == "1" ]]; then
    showline
fi

# load dir_colors if it exists
[ -f ~/.dir_colors ] && eval $(dircolors -b ~/.dir_colors)

# run the custom configuration hook
custom_hook
