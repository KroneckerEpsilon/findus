    function echo_findus
        function _findus_frame --argument ears leye reye offset name
            clear
            printf "%*s         ______ _           _     \n" $offset ""
            printf "%*s         |  ___(_)         | |    \n" $offset ""
            printf "%*s         | |_   _ _ __   __| |%s   %s ___  \n" $offset "" $ears $ears
            printf "%*s         |  _| | | '_ \ / _` | | | / __| \n" $offset ""
            printf "%*s         | |   | | | | | (_| ( %s×%s \\__ \\ \n" $offset "" $leye $reye
            printf "%*s         \\_|   |_|_| |_|\\__,_|\\___/|___/ %s\n" $offset "" $name
            echo ""
        end
    
        set_color blue
    
        _findus_frame "Λ" ">" "<" 0 ""
        sleep 0.15
    
        _findus_frame "Λ" ">" "<" 0 "b"
        sleep 0.15
        
        _findus_frame "_" ">" "<" 0 "by"
        sleep 0.15
    
        _findus_frame "_" "-" "-" 0 "by "
        sleep 0.15
        
        _findus_frame "_" "-" "-" 0 "by J"
        sleep 0.15
    
        _findus_frame "Λ" "-" "-" 0 "by JK"
        sleep 0.15
    
        _findus_frame "Λ" ">" "<" 0 "by JK"
        sleep 0.2
    
        set_color normal
    end


    function findus_help
        echo_findus
        echo ""
        echo "                Usage:"
        echo "                  findus <directory> <pattern>"
        echo
        echo "                Options:"
        echo "                  -h, --help     Show this help message"
        echo
        echo "                Example:"
        echo "                  findus . \"*.cpp\""
        echo ""
    end

    function findus
   
        if test (count $argv) -gt 0
            switch $argv[1]
                case -h --help
                    findus_help
                    return 0
            end
        end

        if test (count $argv) -ne 2
            echo ""
            echo "            [FINDUS] Error: invalid number of arguments."
            findus_help
            return 1
        end

        set dir $argv[1]
        set pattern $argv[2]

        if not test -d $dir
            echo "" 
            echo "            [FINDUS] Error: '$dir' is not a directory."
            findus_help
            return 1
        end
        
        echo_findus
        echo "           FINDING $pattern in $dir" 
        echo 
        # Nur Textfiles sammeln
        set files
        for f in (find $dir -type f -name $pattern)
            set mime (file --mime-type -b $f)
            if string match -q "text/*" $mime
                set files $files $f
            end
        end
    
        test (count $files) -eq 0; and echo "No text files found."; and return
        while true
            set selected (
                printf "%s\n" $files | fzf \
                    --prompt="🐟 Findus > " \
                    --preview='sed -n "1,200p" {}' \
                    --preview-window=right:60%:wrap \
                    --border \
                    --height=90%
            )
        
            # ESC / Ctrl-C → raus aus dem Browser
            test -z "$selected"; and break
        
            vim $selected
        end
    end


    alias findus-cpp-classes 'echo_findus && echo "           FINDING C++ CLASSES" && echo && grep -nE "^\s*(class|struct)\s+\w+" $(find . -name "*.h" -o -name "*.hh" -o -name "*.hpp")'

    function findus-py-classes
        echo_findus
        echo "           FINDING PYTHON CLASSES"
        echo
    
        grep -nE '^\s*class\s+[A-Za-z_][A-Za-z0-9_]*' \
            (find . -name "*.py")
    end

    
    function findus-cpp-regex
        set cname $argv[1]
    
        if test -z "$cname"
            echo "usage: findus-cpp-regex <Regex>"
            return 1
        end
    
        echo_findus
        echo "         FINDING REGEX" 
        echo
        grep -nE "\s*($cname)\b" $(find . -name "*.c" -o -name "*.cc" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.hh")
    end

    function findus-py-regex
        set regex $argv[1]
    
        if test -z "$regex"
            echo "usage: findus-py-regex <Regex>"
            return 1
        end
    
        echo_findus
        echo "         FINDING REGEX (PYTHON)"
        echo
    
        grep -nE "$regex" (find . -name "*.py")
    end

    function findus-cpp-children
        set green "\033[32m"
        set red "\033[31m"
        set reset "\033[0m"
        echo_findus 
        echo "           FINDING CHILD CLASS DEPENDENCIES" 
        echo 
        find . \( -name "*.h" -o -name "*.hh" \) \
        | xargs grep -nE '^\s*(class|struct)\s+\w+\s*:\s*public\s+' \
        | awk -v GREEN="$green" -v RED="$red" -v RESET="$reset" '
            {
                # file:line:code
                split($0, parts, ":")
                file = parts[1]
                line = parts[2]
                code = substr($0, index($0, parts[3]))
    
                if (match(code,
                    /(class|struct)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*:[[:space:]]*public[[:space:]]+([A-Za-z_:][A-Za-z0-9_:]*)/,
                    m))
                {
                    printf "In %s%s%s:%s, class %s%s%s is a child of %s%s%s\n",
                        GREEN, file, RESET,
                        line,
                        RED, m[2], RESET,
                        RED, m[3], RESET
                }
            }
        '
    end

    function findus-py-children
        set green "\033[32m"
        set red "\033[31m"
        set reset "\033[0m"
    
        echo_findus
        echo "           FINDING PYTHON CLASS DEPENDENCIES"
        echo
    
        grep -nE '^\s*class\s+[A-Za-z_][A-Za-z0-9_]*\s*\(.*\)\s*:' \
            (find . -name "*.py") \
        | awk -v GREEN="$green" -v RED="$red" -v RESET="$reset" '
            {
                # file:line:code
                split($0, parts, ":")
                file = parts[1]
                line = parts[2]
                code = substr($0, index($0, parts[3]))
    
                if (match(code,
                    /class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(([^)]*)\)/,
                    m))
                {
                    printf "In %s%s%s:%s, class %s%s%s inherits from %s%s%s\n",
                        GREEN, file, RESET,
                        line,
                        RED, m[1], RESET,
                        RED, m[2], RESET
                }
            }
        '
    end
