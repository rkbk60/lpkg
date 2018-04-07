#!/usr/bin/fish

function lpkg
    # make Ctrl-C trap to exit function
    trap 'return 140' EXIT

    # check arguments
    set -l show_help 1
    set -q argv
        and set show_help (test "$argv" = ""; echo $status)
        or  set show_help 0
    for arg in $argv
        switch $arg; case "-h" "--help" "help"
            set show_help 0
        end
    end
    if test $show_help -eq 0
        cat (dirname (status -f))/../help/lpkg
        return
    end

    # search fish_history
    set -l history_path "$HOME/.local/share/fish/fish_history"
    set -q XDG_DATA_HOME
        and test -d $XDG_DATA_HOME
        and set history_path "$XDG_DATA_HOME/fish/fish_history"
    if test ! -f $history_path
        echo "Error: cannot find 'fish_history'."
        return 129
    end

    # detect install/uninstall/check commands
    set -l command (string join " " $argv)
    set -l user_command (string replace -r "^sudo " "" $command)
    set -l install ""
    set -l uninstall ""
    set -l check ""
    switch $user_command
        case "pacman" "yaourt"
            if test $command = "sudo yaourt"
                echo "Error: '$command' cannot use in this command." \
                     "Use '$user_command'."
                return 130
            end
            set install   "$command -S"
            set uninstall "$command -R"
            set check     "$user_command -Q"
        case "apt" "apt-get" "pkg"
            set install   "$command install"
            set uninstall "$command remove"
            set check     "dpkg -L"
        case "apt-get"
            set install   "apt-get install"
            set uninstall "apt-get remove"
            set check     "dpkg -L"
        case "dnf" "yum"
            set install   "$command install"
            set uninstall "$command remove"
            set check     "rpm -ql"
        case "*"
            echo "Error: '$command' cannot use in this command."
            return 131
    end

    # get installed/uninstalled package's names
    set -l tag_install   "<s>"
    set -l tag_uninstall "<r>"
    set -l list (cat $history_path \
                    | sed -e "s/;  */\n- cmd: /g" \
                    | grep -E "^- cmd: (($install)|($uninstall)) " \
                    | sed -e 's/[\\\\|\/|<|>]/ /g'  \
                    | sed -e "s/^- cmd: $install /$tag_install /g" \
                    | sed -e "s/^- cmd: $uninstall /$tag_uninstall /g")

    # filter packages you're using now
    set -l separator "|"
    set -l result "$separator"
    set -l is_install_command 1
    set -l flag_ignore 1
    for i in (string split " " $list)
        switch $i
            case $tag_install
                set is_install_command 0
            case $tag_uninstall
                set is_install_command 1
            case "" "-*" "#*"
                # empty line, option, comment will ignore
            case "*"
                set -l j "$separator$i$separator"
                set -l k "$result$i$separator"
                if test $is_install_command -eq 0
                    if string match -q "*$j*" $result > /dev/null
                        # do not regist
                    else if test $check = ""
                        set result "$k"
                    else
                        eval "$check $i" > /dev/null
                        and set result "$k"
                    end
                else # equals "test is_install_command -eq 1"
                    set result (string replace "$j" $separator $result)
                end
        end
    end

    # output list
    if test $result = $separator
        echo "Notice: there are no packages installed by '$command'."
    else
        echo "#uname:" (uname -rm)
        echo "#command: $command"
        string trim -c $separator $result | string split $separator | sort
    end
end
