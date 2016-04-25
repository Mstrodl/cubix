# ~/.cshrc: executed by cshell

#if [ $(exists /home/$USER/.csh_aliases) ] then
#    $(/home/$USER/.csh_aliases)
#fi

#setting aliases
alias yapisy='sudo yapi -Sy'

## PS1 with all blue but commands are white
#set PS1 ;\033[0;36][%u@%h %w]$\033[1;37]
set PS1 ;[%u@%h %w]$
set PS2 ;>
