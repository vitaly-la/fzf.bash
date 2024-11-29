if [[ $- =~ i ]]; then

__fzf_history__() {
    unique="$(mktemp)"
    filtered="$(mktemp)"
    input=''
    pattern=''
    total=29
    offset=0
    line=1

    fc -lr -2147483648 | awk '{ key=substr($0, index($0, $2)); if (!seen[key]++) print }' | tac > "$unique"

    while true; do
        grep "$pattern" "$unique" > "$filtered"
        lines="$(wc -l < "$filtered")"
        shown="$(head -n -"$offset" "$filtered" | tail -n "$total")"
        shown_lines="$(echo "$shown" | wc -l)"
        output="$(echo "$shown" | tail -n "$line" | head -n 1)"

        clear
        echo "$shown" | head -n "$(( shown_lines - line ))" | awk '{ print "  "$0 }'
        echo "> $output"
        echo "$shown" | tail -n "$(( line - 1 ))" | awk '{ print "  "$0 }'
        echo '--------------------------------------------------------------------------------'
        echo -n "> $input"

        IFS= read -rsn1 chr

        if [[ -z "$chr" ]]; then
            break

        elif [[ "$chr" == $'\x08' || "$chr" == $'\x7f' ]]; then
            if [[ -n "$input" ]]; then
                input="${input::-1}"
                pattern="${pattern:0:-3}"
                offset=0
                line=1
            fi

        elif [[ "$chr" == $'\e' ]]; then
            IFS= read -rsn2 chr

            if [[ "$chr" == '[A' ]]; then
                if (( line < shown_lines )); then
                    line="$(( line + 1 ))"
                elif (( offset < lines - shown_lines )); then
                    offset="$(( offset + 1 ))"
                fi
            elif [[ "$chr" == '[B' ]]; then
                if (( line > 1 )); then
                    line="$(( line - 1 ))"
                elif (( offset > 0 )); then
                    offset="$(( offset - 1 ))"
                fi
            fi

        elif [[ "$chr" =~ [[:print:]] ]]; then
            input="$input$chr"
            pattern="$pattern$chr.*"
            offset=0
            line=1
        fi
    done

    rm -f "$unique" "$filtered"
    echo

    READLINE_LINE=${output#*$'\t '}
    if [[ -z "$READLINE_POINT" ]]; then
        echo "$READLINE_LINE"
    else
        READLINE_POINT=0x7fffffff
    fi
}

bind -m emacs-standard '"\er": redraw-current-line'

bind -m vi-command '"\C-z": emacs-editing-mode'
bind -m vi-insert '"\C-z": emacs-editing-mode'
bind -m emacs-standard '"\C-z": vi-editing-mode'

if (( BASH_VERSINFO[0] < 4 )); then
    bind -m emacs-standard '"\C-r": "\C-e \C-u\C-y\ey\C-u`__fzf_history__`\e\C-e\er"'
    bind -m vi-command '"\C-r": "\C-z\C-r\C-z"'
    bind -m vi-insert '"\C-r": "\C-z\C-r\C-z"'
else
    bind -m emacs-standard -x '"\C-r": __fzf_history__'
    bind -m vi-command -x '"\C-r": __fzf_history__'
    bind -m vi-insert -x '"\C-r": __fzf_history__'
fi

fi
