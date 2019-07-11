for i in "$@"; do
    if [[ $i == *=* ]]; then
        parameter=${i%%=*}
        value=${i##*=}
        if [[ "$value" =~ ' ' ]]; then
            echo "Command line: setting $parameter to" "\"${value:-(empty)}\""
            eval $parameter="\"$value\""
        else
            echo "Command line: setting $parameter to" "${value:-(empty)}"
            eval $parameter=$value
        fi
    fi
done
