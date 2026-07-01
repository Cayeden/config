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
        ssh-add ~/.ssh/id_ed25519_personal ~/.ssh/id_ed25519_school
    else if set -q SSH_AUTH_SOCK; and test $agent_run_state -eq 1
        ssh-add ~/.ssh/id_ed25519_personal ~/.ssh/id_ed25519_school
    end

    set -e envfile
end
