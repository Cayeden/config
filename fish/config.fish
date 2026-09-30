source /usr/share/cachyos-fish-config/cachyos-config.fish

set -gx BROWSER /usr/local/bin/helium

if status is-interactive
    set -g envfile ~/.ssh/agent.env

    function agent_load_env
        if test -f $envfile
            source $envfile >/dev/null 2>&1
        end
    end

    function agent_start
        umask 077
        ssh-agent -c > $envfile
        source $envfile >/dev/null 2>&1
    end

    agent_load_env

    ssh-add -l >/dev/null 2>&1
    set agent_run_state $status

    if not set -q SSH_AUTH_SOCK; or test $agent_run_state -eq 2
        agent_start
        ssh-add
    else if set -q SSH_AUTH_SOCK; and test $agent_run_state -eq 1
        ssh-add
    end

    set -e envfile
end
fish_add_path $HOME/.local/npm/bin

fish_add_path $HOME/.local/bin

# Added by LM Studio CLI tool (lms)
fish_add_path $HOME/.lmstudio/bin
