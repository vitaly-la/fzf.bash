#!/usr/bin/env -S bash -i

ctrl_c() {
    rm -f "$unique" "$filtered"
    echo
    history -c
    exit
}

main() {
    hst="$HOME/.bash_history"
    unique="$(mktemp)"
    filtered="$(mktemp)"
    input=''
    pattern=''
    total=29
    offset=0
    line=1

    tac "$hst" | awk '!seen[$0]++' | tac > "$unique"

    trap ctrl_c INT

    while true ; do
        grep "$pattern" "$unique" > "$filtered"
        lines="$(wc -l < "$filtered")"
        shown="$(head -n -"$offset" "$filtered" | tail -n "$total")"
        shown_lines="$(echo "$shown" | wc -l)"
        select="$(echo "$shown" | tail -n "$line" | head -n 1)"

        clear
        echo "$shown" | head -n "$(( shown_lines - line ))" | awk '{ print "  "$0 }'
        echo "> $select"
        echo "$shown" | tail -n "$(( line - 1 ))" | awk '{ print "  "$0 }'
        echo '--------------------------------------------------------------------------------'
        echo -n "> $input"

        IFS= read -rsn1 chr

        if [[ -z "$chr" ]] ; then
            break

        elif [[ "$chr" == $'\x08' || "$chr" == $'\x7f' ]] ; then
            if [[ -n "$input" ]] ; then
                input="${input::-1}"
                pattern="${pattern:0:-3}"
                offset=0
                line=1
            fi

        elif [[ "$chr" == $'\e' ]]; then
            IFS= read -rsn2 chr

            if [[ "$chr" == '[A' ]] ; then
                if (( line < shown_lines )) ; then
                    line="$(( line + 1 ))"
                elif (( offset < lines - shown_lines )) ; then
                    offset="$(( offset + 1 ))"
                fi
            elif [[ "$chr" == '[B' ]] ; then
                if (( line > 1 )) ; then
                    line="$(( line - 1 ))"
                elif (( offset > 0 )) ; then
                    offset="$(( offset - 1 ))"
                fi
            fi

        elif [[ "$chr" =~ [[:print:]] ]] ; then
            input="$input$chr"
            pattern="$pattern$chr.*"
            offset=0
            line=1
        fi
    done

    rm -f "$unique" "$filtered"
    echo
    echo "${PS1@P}$select"
    if [[ "$select" != "$(tail -n 1 "$HISTFILE")" ]] ; then
        echo "$select" >> "$HISTFILE"
    fi
    history -c
    eval "$select"
}

main
