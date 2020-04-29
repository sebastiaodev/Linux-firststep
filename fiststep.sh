################## 3DB Linux ##################
##### Config by: Sebastiao Santos         #####
##### DEVOPS: RHCE, LPIC-2, Novel CLA,    ##### 
##### Cloud Architect                     #####
##### MSN/email: sebastiao@3db.net.br     #####
##### Site: www.3db.net.br                #####
###############################################
# Post install script

# Run as root

# Update SO
yum -y update
# Install Epel Repo
yum -y install epel-release
# Install others tools
yum -y install telnet wget vim net-tools unzip bind-utils htop nmon tmux ntp tzdata
# Disable selinux
sudo setenforce 0
sed -i '/SELINUX=enforcing/s/enforcing/disabled/' /etc/selinux/config
# disable firewalld
systemctl stop firewalld
systemctl disable firewalld
# disable postfix
systemctl stop postfix
systemctl disable postfix
# Replace /etc/profile
cat <<EOF > /etc/profile
################## 3DB Linux ##################
##### Config by: Sebastiao Santos         #####
##### DEVOPS: RHCE, LPIC-2, Novel CLA,    ##### 
##### Cloud Architect                     #####
##### MSN/email: sebastiao@3db.net.br     #####
##### Site: www.3db.net.br                #####
###############################################
# /etc/profile

# System wide environment and startup programs, for login setup
# Functions and aliases go in /etc/bashrc

pathmunge () {
	if ! echo $PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
	   if [ "$2" = "after" ] ; then
	      PATH=$PATH:$1
	   else
	      PATH=$1:$PATH
	   fi
	fi
}

# ksh workaround
if [ -z "$EUID" -a -x /usr/bin/id ]; then 
	EUID=`id -u`
	UID=`id -ru`
fi

# Path manipulation
if [ "$EUID" = "0" ]; then
	pathmunge /sbin
	pathmunge /usr/sbin
	pathmunge /usr/local/sbin
fi

# No core files by default
ulimit -S -c 0 > /dev/null 2>&1

if [ -x /usr/bin/id ]; then
	USER="`id -un`"
	LOGNAME=$USER
	MAIL="/var/spool/mail/$USER"
fi

HOSTNAME=`/bin/hostname`
HISTSIZE=1000

if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ]; then
    INPUTRC=/etc/inputrc
fi

PS1='\[\033[1;33m\]\u\[\033[1;37m\]@\[\033[1;32m\]\h\[\033[1;37m\]:\[\033[1;31m\]\w \[\033[1;36m\]\\$ \[\033[0m\]'

export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE INPUTRC PS1

for i in /etc/profile.d/*.sh ; do
    if [ -r "$i" ]; then
    	. $i
    fi
done

unset i
unset pathmunge
EOF

# Create TMUX conf
cat <<EOF > /home/opc/.tmux.conf
# remap prefix to Control + a
set -g prefix C-a

# bind 'C-a C-a' to type 'C-a'
bind C-a send-prefix
unbind C-b

# reload config
bind-key r source-file ~/.tmux.conf \; display-message "Configuration reloaded"

# neovim integration
set-option -sg escape-time 0

# # Start windows and panes index at 1, not 0.
set -g base-index 1
setw -g pane-base-index 1

# tmux vim-mode
setw -g mode-keys vi

# TERM
set-option -g default-terminal "screen-256color"

# disable auto renaming
set -g automatic-rename off

# edit config
bind-key e new-window -n 'conf' '${EDITOR:-vim} ~/.tmux.conf && tmux source ~/.tmux.conf && tmux display "~/.tmux.conf sourced"'
bind-key '/' new-window 'man tmux'

# set display timelimit
set-option -g display-panes-time 2000
set-option -g display-time 1000

# history size
set-option -g history-limit 100000


# select panes
bind-key k select-pane -U
bind-key h select-pane -L
bind-key j select-pane -D
bind-key l select-pane -R


# resize panes
bind-key -r J resize-pane -D 1
bind-key -r K resize-pane -U 1
bind-key -r H resize-pane -L 1
bind-key -r L resize-pane -R 1

# better pane split bindings with current path (tmux 1.9+)
bind-key _ split-window -h -c "#{pane_current_path}"    # vertical split
bind-key - split-window -v -c "#{pane_current_path}"    # horizontal split

# List of plugins.
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-yank'

# Initialize TPM (keep this line at the very bottom of your tmux.conf).
run -b '~/.tmux/plugins/tpm/tpm'
EOF

# tmux start
tmux start
# Create session "base"
sudo su - opc -c "tmux -2 -f ~/.tmux.conf new -s base -x 120 -y 47"

# NTP change timezone
timedatectl set-timezone America/Sao_Paulo
# Add ntp server list
cat <<EOF > /etc/ntp/step-tickers
# List of NTP servers used by the ntpdate service.
a.ntp.br
b.ntp.br
c.ntp.br
EOF
# Enable and start ntp service
systemctl enable ntpd
systemctl restart ntpd




