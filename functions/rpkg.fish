#/usr/bin/fish

function rpkg
    # make Ctrl-C trap to exit function
    trap 'return 140' EXIT

    # check arguments
    set -l main_arg  ""
    set -l show_help 1
    set -l do_force  1
    set -q argv
        and set show_help (test "$argv" = ""; echo $status)
        or  set show_help 0
    for arg in $argv
        switch $arg;
            case "-h" "--help" "help"
                set show_help 0
            case "-y"
                set do_force 0
            case "*"
                if test $main_arg = ""
                    set main_arg $arg
                else
                    echo "Error: arguments are too mach."
                    return 129
                end
        end
    end
    if test $show_help -eq 0
        cat (dirname (status -f))/../help/rpkg
        return
    end

    # get list
    set -l list ""
    if string match -qr "^https?://*" "$argv[1]"
        set -l get_command ""
        if test (type curl > /dev/null; echo $status) -eq 0
            set get_command "curl"
        else if test (type wget > /dev/null; echo $status) -eq 0
            set get_command "wget"
        else
            echo "Error: you have to install 'curl' or 'wget' to use this command."
            return 130
        end
        set list (eval "$get_command $argv[1]")
    else if test -f $argv[1]
        set list (cat $argv[1])
    else
        echo "Error: set package list."
        return 131
    end

    # detect package manager commands
    set -l command \
        (string match "*#command: *" $list | sed -e 's/#command: //g' | string trim)
    set -l pre_command   ""
    set -l check_command ""
    set -l force_option  ""
    switch $command
        case "apt" "apt-get" "pkg" "sudo apt" "sudo apt-get"
            set pre_command   "$command update" "$command upgrade"
            set check_command "$command info"
            set force_option  "-y"
        case "dnf" "yum" "sudo dnf" "sudo yum"
            set pre_command   "$command update"
            set check_command "$command info"
            set force_option  "-y"
        case "pacman" "sudo pacman"
            set pre_command   "$command -Syya"
            set check_command "$command -Qi"
            set force_option  "--force"
        case "yaourt"
            set pre_command   "$command -Syua"
            set check_command "$command -Qi"
            set force_option  "--force"
        case ""
            echo "Error: cannot detect package manager."
        case "*"
            echo "Error: '$command' cannot use in this command."
            return 133
    end

    test $do_force -eq 0
        and set force_option ""

    # check information
    set -l list_uname "unknown"
    set -l this_uname (uname -rm)
    set -l can_install_list
    set -l cannot_install_list
    for i in (string split "\n" $list)
        switch $i
            case "#uname: *"
                set list_uname (string replace "#uname: " "" $i)
            case "-*" "" "#*"
                # ignore
            case "*"
                eval "$check_command $i" > /dev/null 2>&1
                test $status -eq 0
                    and set can_install_list    $can_install_list    "$i"
                    or  set cannot_install_list $cannot_install_list "$i"
        end
    end

    # show information
    set -l counted (count $can_install_list)
    set_color brgreen; echo -n "==> "; set_color normal
    echo "install packages with 'rpkg'."
    echo
    echo "List uname: $list_uname"
    echo "This uname: $this_uname"
    echo
    echo "command to will use: $command"
    echo
    echo "Install packages($counted):"
    echo $can_install_list
    if test "$cannot_install_list" != ""
        echo
        echo "Ignore packages(may not exist):"
        echo $cannot_install_list
    end
    echo
    if test $do_force -ne 0
        read -P "Proceed with installation? [y/N] " do_installation
        string match -iqv "y" $do_installation
            and return
    end

    # installation
    for i in $pre_command
        echo
        set_color brblue; echo -n "==> "; set_color normal
        echo $i
        eval $i
        test $status -ne 0
            and return $status

    end
    echo
    set_color brblue; echo -n "==> "; set_color normal
    echo "$command [PACKAGES] $force"
    eval "$command $can_install_list $force_option"
    return $status
end
