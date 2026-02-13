#/usr/bin/bash

echo_findus() {
    _findus_frame() {
        local ears="$1" leye="$2" reye="$3" offset="$4" name="$5"
        clear
        printf "%*s         ______ _           _     \n" "$offset" ""
        printf "%*s         |  ___(_)         | |    \n" "$offset" ""
        printf "%*s         | |_   _ _ __   __| |%s   %s ___  \n" "$offset" "" "$ears" "$ears"
        printf "%*s         |  _| | | '_ \\ / _\` | | | / __| \n" "$offset" ""
        printf "%*s         | |   | | | | | (_| ( %s×%s \\__ \\ \n" "$offset" "" "$leye" "$reye"
        printf "%*s         \\_|   |_|_| |_|\\__,_|\\___/|___/ %s\n" "$offset" "" "$name"
        echo
    }

    printf "\033[34m" # blue

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

    printf "\033[0m"
}

findus_help() {
    echo_findus
    echo
    echo "                Usage:"
    echo "                  findus <directory> <pattern>"
    echo
    echo "                Options:"
    echo "                  -h, --help     Show this help message"
    echo
    echo "                Example:"
    echo "                  findus . \"*.cpp\""
    echo
}

findus() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        findus_help
        return 0
    fi

    if [[ $# -ne 2 ]]; then
        echo
        echo "            [FINDUS] Error: invalid number of arguments."
        findus_help
        return 1
    fi

    local dir="$1"
    local pattern="$2"

    if [[ ! -d "$dir" ]]; then
        echo
        echo "            [FINDUS] Error: '$dir' is not a directory."
        findus_help
        return 1
    fi

    echo_findus
    echo "           FINDING $pattern in $dir"
    echo

    mapfile -t files < <(
        find "$dir" -type f -name "$pattern" -print0 |
        while IFS= read -r -d '' f; do
            mime=$(file --mime-type -b "$f")
            [[ "$mime" == text/* ]] && echo "$f"
        done
    )

    [[ ${#files[@]} -eq 0 ]] && echo "No text files found." && return

    while true; do
        selected=$(printf "%s\n" "${files[@]}" | fzf \
            --prompt="🐟 Findus > " \
            --preview='sed -n "1,200p" {}' \
            --preview-window=right:60%:wrap \
            --border \
            --height=90%)

        [[ -z "$selected" ]] && break
        vim "$selected"
    done
}

alias findus-cpp-classes='echo_findus && echo "           FINDING C++ CLASSES" && echo && grep -nE "^\s*(class|struct)\s+\w+" $(find . -name "*.h" -o -name "*.hh" -o -name "*.hpp")'

findus-py-classes() {
    echo_findus
    echo "           FINDING PYTHON CLASSES"
    echo
    grep -nE '^\s*class\s+[A-Za-z_][A-Za-z0-9_]*' $(find . -name "*.py")
}

findus-cpp-regex() {
    local regex="$1"
    [[ -z "$regex" ]] && echo "usage: findus-cpp-regex <Regex>" && return 1

    echo_findus
    echo "         FINDING C++ REGEX"
    echo
    grep -nE "$regex" $(find . -name "*.c" -o -name "*.cc" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.hh")
}

findus-py-regex() {
    local regex="$1"
    [[ -z "$regex" ]] && echo "usage: findus-py-regex <Regex>" && return 1

    echo_findus
    echo "         FINDING REGEX (PYTHON)"
    echo
    grep -nE "$regex" $(find . -name "*.py")
}

findus-cpp-children() {
    local GREEN="\033[32m" RED="\033[31m" RESET="\033[0m"

    echo_findus
    echo "           FINDING CHILD CLASS DEPENDENCIES"
    echo

    find . \( -name "*.h" -o -name "*.hh" \) |
    xargs grep -nE '^\s*(class|struct)\s+\w+\s*:\s*public\s+' |
    awk -v GREEN="$GREEN" -v RED="$RED" -v RESET="$RESET" '
    {
        split($0, p, ":")
        if (match($0, /(class|struct)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*:[[:space:]]*public[[:space:]]+([A-Za-z_:][A-Za-z0-9_:]*)/, m))
            printf "In %s%s%s:%s, class %s%s%s is a child of %s%s%s\n",
                GREEN,p[1],RESET,p[2],RED,m[2],RESET,RED,m[3],RESET
    }'
}

findus-py-children() {
    local GREEN="\033[32m" RED="\033[31m" RESET="\033[0m"

    echo_findus
    echo "           FINDING PYTHON CLASS DEPENDENCIES"
    echo

    grep -nE '^\s*class\s+[A-Za-z_][A-Za-z0-9_]*\s*\(.*\)\s*:' $(find . -name "*.py") |
    awk -v GREEN="$GREEN" -v RED="$RED" -v RESET="$RESET" '
    {
        split($0, p, ":")
        if (match($0, /class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(([^)]*)\)/, m))
            printf "In %s%s%s:%s, class %s%s%s inherits from %s%s%s\n",
                GREEN,p[1],RESET,p[2],RED,m[1],RESET,RED,m[2],RESET
    }'
}

