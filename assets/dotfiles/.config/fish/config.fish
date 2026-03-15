# Hide default fish greeting
set fish_greeting

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Lambda-style prompt
function fish_prompt
    set -l last_status $status
    if not set -q __fish_prompt_hostname
        set -g __fish_prompt_hostname (hostname | cut -d . -f 1)
    end
    if not set -q __fish_prompt_char
        switch (id -u)
            case 0
                set -g __fish_prompt_char '#'
            case '*'
                set -g __fish_prompt_char (set_color red; echo λ)
        end
    end

    set -l normal (set_color normal)
    set -l white (set_color FFFFFF)
    set -l red (set_color F00)
    set -l orange (set_color df5f00)
    set -l limegreen (set_color 87ff00)
    set -l turquoise (set_color 5fdfff)

    set -g __fish_git_prompt_char_stateseparator ' '
    set -g __fish_git_prompt_color 5fdfff
    set -g __fish_git_prompt_color_flags df5f00
    set -g __fish_git_prompt_color_prefix white
    set -g __fish_git_prompt_color_suffix white
    set -g __fish_git_prompt_showdirtystate true
    set -g __fish_git_prompt_showuntrackedfiles true
    set -g __fish_git_prompt_showstashstate true
    set -g __fish_git_prompt_show_informative_status true

    echo "$white╭─$red$USER$white at $orange$__fish_prompt_hostname$white in $limegreen"(pwd | sed "s=$HOME=⌁=")"$turquoise"
    __fish_git_prompt " (%s)"
    echo

    echo -n "$white╰─$__fish_prompt_char $normal"
end

# !! and !$ support
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]; commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

# Fancy command history
function history
    builtin history --show-time='%F %T '
end

# Handy backup
function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 to DIR2 if directory
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# Aliases
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='psmem | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias hw='hwinfo --short'
alias big="expac -H M '%m\t%n' | sort -h | nl"


# Apply pywal colors if available
if type "wal" > /dev/null 2>&1
    cat ~/.cache/wal/sequences
end

# Starship support
starship init fish | source

# Launch fastfetch on shell open (all info handled by fastfetch config)
# fastfetch --logo blackarch
fastfetch

# Post-execution hook — only on failure
function postexec --on-event fish_postexec
    if set -q __last_command_not_found
        set -e __last_command_not_found
        return
    end

    if test $status -ne 0
        set_color red
        echo "❌ Task failed. Exit status: $status."
        set_color normal
    end
end

# Command not found
function fish_command_not_found
    set_color red
    echo "❓ Command '$argv' not found. Are you sure it's installed?"
    set_color normal
    set -g __last_command_not_found 1
end

