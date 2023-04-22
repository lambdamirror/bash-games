#!/bin/bash

APP_NAME=$(basename $0)
APP_NAME=${0##*[\\/]}

cBlack=0
cRed=1
cGreen=2
cYellow=3
cBlue=4
cFuchsia=5
cCyan=6
cWhite=7
colorTable=($cRed $cGreen $cYellow $cBlue $cFuchsia $cCyan $cWhite)

iLeft=0
iTop=0

declare -A figValues=(
    [k]=0 [q]=9 [r]=5 [b]=3 [n]=3 [p]=1
    [K]=0 [Q]=9 [R]=5 [B]=3 [N]=3 [P]=1
)
declare -A figUnicodes=(
    [k]="\u2654" [q]="\u2655" [r]="\u2656" [b]="\u2657" [n]="\u2658" [p]="\u2659"
    [K]="\u265A" [Q]="\u265B" [R]="\u265C" [B]="\u265D" [N]="\u265E" [P]="\u265F"
)
state="rnbqkbnr/pppppppp/00000000/00000000/00000000/00000000/PPPPPPPP/RNBQKBNR"
state="rnbqkbnr/00000000/00000000/00000000/rnbqkbnr/00000000/PPPPPPPP/RNBQKBNR"

function range() {
    local array=()
    for ((i = $1; i < $2; i++)); do
        array+=("$i")
    done
    echo -ne ${array[@]}
}

function setChar() {
    local str i j offset char
    str=$1
    i=$2
    ((j = $i + 1))
    char=$3
    ((offset = ${#str} - ${i}))
    echo -ne "${str:0:i}$char${str:j:offset}"
}

function contains() {
    for x in $2; do
        [[ "$x" == "$1" ]] && return 0
    done
    return 1
}

function fIndex() {
    local i r c
    r=$1
    c=$2
    ((i = ${r} * 8 + ${r} + ${c}))
    echo -ne $i
}

function row() {
    local i r
    i=$1
    ((r = ${i} / 9))
    echo -ne $r
}

function col() {
    local i c
    i=$1
    ((c = ${i} % 9))
    echo -ne $c
}

function sign() {
    echo "$(($1 < 0 ? -1 : 1))"
}

function abs() {
    echo "$(($1 * $(sign $1)))"
}

function canMove() {
    local pos next r1 c1 r2 c2 f t cdif rdif
    pos=$1
    next=$2
    r1=$(row $pos)
    c1=$(col $pos)
    r2=$(row $next)
    c2=$(col $next)
    ((cdif = c1 - c2))
    ((rdif = r1 - r2))
    f=${state:pos:1}
    t=${state:next:1}
    # check army blocks
    fWhite=false
    if [[ ${f,,} == $f ]] && [[ $f != "0" ]]; then fWhite=true 
    fi
    tWhite=false
    if [[ ${t,,} == $t ]] && [[ $t != "0" ]]; then tWhite=true 
    fi
    # echo next=$next t=$t fWhite=$fWhite tWhite=$tWhite
    if [[ $f == "0" ]] || [[ $fWhite == $tWhite ]]; then
        return 1
    fi
    # validate pieces' move
    if [[ $f == "0" ]]; then
        return 1
    elif [[ $f == "k" || $f == "K" ]]; then
        return 1
    elif [[ $f == "q" || $f == "Q" ]]; then
        return 1
    elif [[ $f == "r" || $f == "R" ]]; then
        if ((r1 == r2 || c1 == c2)); then
            return 0
        fi
    elif [[ $f == "b" || $f == "B" ]]; then
        if ((cdif != 0 && $(abs $cdif) == $(abs $rdif))); then
            return 0
        fi
    # knight
    elif [[ $f == "n" || $f == "N" ]]; then
        if ((cdif != 0 && rdif != 0 && $(abs $cdif) + $(abs $rdif) == 3)); then
            return 0
        fi
    # white pawn
    elif [[ $f == "p" ]]; then
        if [[ $t == "0" ]]; then
            # move to empty
            if [[ $c2 == $c1 && $r2 > $r1 ]]; then
                if [[ $r1 == 1 && $r2 -lt 4 ]]; then
                    return 0
                elif ((r2 == (r1 + 1))); then
                    return 0
                fi
            fi
        elif [[ ${t^^} == $t ]]; then
            # move to opponent's pieces
            if (((c2 == (c1 + 1) || c2 == (c1 - 1)) && r2 == (r1 + 1))); then
                return 0
            fi
        fi
    # black pawn
    elif [[ $f == "P" ]]; then
        if [[ $t == "0" ]]; then
            # move to empty
            if [[ $c2 == $c1 && $r2 < $r1 ]]; then
                if [[ $r1 == 6 && $r2 -gt 3 ]]; then
                    return 0
                elif ((r2 == (r1 - 1))); then
                    return 0
                fi
            fi
        elif [[ ${t,,} == $t ]]; then
            # move to opponent's pieces
            if (((c2 == (c1 + 1) || c2 == (c1 - 1)) && r2 == (r1 - 1))); then
                return 0
            fi
        fi
    fi
    return 1
}

function move() {
    local pos next f
    pos=$1
    next=$2
    f=${state:pos:1}
    state=$(setChar $state $pos "0")
    state=$(setChar $state $next $f)
}

function drawCell() {
    local f i r c
    f=$1
    i=$2
    ((r = ${i} / 9))
    ((c = ${i} % 9))
    if (((r + c) % 2 == 0)); then
        echo -ne "\033[3${cBlack}m\033[4${cGreen}m"
    else
        echo -ne "\033[3${cBlack}m\033[4${cWhite}m"
    fi

    if [[ $f == "0" ]]; then
        printf " %b " "\u2003"
    else
        printf " %b " "${figUnicodes[$f]}"
    fi
    echo -ne "\033[0m"
}

function drawBoard() {
    clear
    local f i
    printf " %b \n" "\u2003"
    for ((i = 0; i < ${#state}; i++)); do
        f=${state:$i:1}
        if [[ $f == "/" ]]; then
            echo -ne "\033[4${cBlack}m"
            printf " %b \n" "\u2003"
        else
            drawCell "${state:$i:1}" $i
        fi
    done
    echo -ne "\033[4${cBlack}m"
    printf " %b \n" "\u2003"
    printf " %b \n" "\u2003"
    echo -ne "\033[0m"
}

# drawBoard
echo -ne "\033[?25l" # hide cursor
start=$state
pos=$(fIndex 4 2)
for ((i = 0; i < ${#state}; i++)); do
    f=${state:$i:1}
    if [[ $f != "/" ]]; then
        if canMove $pos $i; then
            sleep 1
            move $pos $i
            # pos=$i
            drawBoard
            sleep 1
            state=$start
            drawBoard
        fi
    fi
done

echo -ne "\033[0m" # reset styling
# drawBoard
# move $pos $next
# sleep 2
# drawBoard
# echo -e "\n"
