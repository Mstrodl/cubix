# ~/.cshrc: executed by cshell

#if [ $(exists /home/$USER/.csh_aliases) ] then
#    $(/home/$USER/.csh_aliases)
#fi

#setting aliases
alias yapisy='sudo yapi -Sy'
alias god='su'

set PS1 ;[%u@%h %w]$
