#!/bin/bash

#SNAKE
trap 'stty echo; tput cnorm; clear; exit' SIGINT

# Game settings
HEIGHT=20
WIDTH=40
SNAKE_HEAD=''
FOOD=''
DELAY=0.1

# Initial snake
snake_x=(20 19 18)
snake_y=(10 10 10)
dir='right'
food_x=0
food_y=0
score=0

# Draw border
draw_border() {
    clear
    # Top border
    echo -n "┌"
    for ((i=1; i<=WIDTH; i++)); do echo -n "─"; done
    echo "┐"
    # Side walls
    for ((i=1; i<=HEIGHT; i++)); do
        echo -n "│"
        for ((j=1; j<=WIDTH; j++)); do echo -n " "; done
        echo "│"
    done
    # Bottom border
    echo -n "└"
    for ((i=1; i<=WIDTH; i++)); do echo -n "─"; done
    echo "┘"
}

# Get body character based on segment direction
get_body_char() {
    local x_prev=$1 y_prev=$2 x_curr=$3 y_curr=$4 x_next=$5 y_next=$6

    local dx1=$((x_curr - x_prev))
    local dy1=$((y_curr - y_prev))
    local dx2=$((x_next - x_curr))
    local dy2=$((y_next - y_curr))

    # Straight horizontal
    if ((dy1 == 0 && dy2 == 0)); then
        echo "═"
    # Straight vertical
    elif ((dx1 == 0 && dx2 == 0)); then
        echo "║"
    # Directional Changes
elif ((dx1 == 1 && dy2 == -1)) || ((dy1 == 1 && dx2 == -1)); then
    echo "╝"  # Right → Up or Down → Left

elif ((dx1 == -1 && dy2 == -1)) || ((dy1 == 1 && dx2 == 1)); then
    echo "╚"  # Left → Up or Down → Right

elif ((dx1 == 1 && dy2 == 1)) || ((dy1 == -1 && dx2 == -1)); then
    echo "╗"  # Right → Down or Up → Left

elif ((dx1 == -1 && dy2 == 1)) || ((dy1 == -1 && dx2 == 1)); then
    echo "╔"  # Left → Down or Up → Right


    else
        echo "·"  # fallback
    fi
}

if ((i == 0)); then
    echo -n "$SNAKE_HEAD"
else
    # Get direction-based body character
    if ((i + 1 < ${#snake_x[@]})); then
        body_char=$(get_body_char "${snake_x[i+1]}" "${snake_y[i+1]}" "${snake_x[i]}" "${snake_y[i]}" "${snake_x[i-1]}" "${snake_y[i-1]}")
    else
        body_char="═"  # fallback for tail
    fi
    echo -n "$body_char"
fi

# Draw snake and food (initial setup)
draw_snake() {
    tput cup $food_y $food_x; echo -n "$FOOD"
    for ((i=0; i<${#snake_x[@]}; i++)); do
        tput cup ${snake_y[$i]} ${snake_x[$i]}
        if ((i == 0)); then
            echo -n "$SNAKE_HEAD"
        else
            # Determine direction
            local x_prev=${snake_x[$((i-1))]}
            local y_prev=${snake_y[$((i-1))]}
            local x_curr=${snake_x[$i]}
            local y_curr=${snake_y[$i]}
            local x_next y_next
            if ((i + 1 < ${#snake_x[@]})); then
                x_next=${snake_x[$((i+1))]}
                y_next=${snake_y[$((i+1))]}
            else
                # Tail: use direction from previous segment
                x_next=$x_curr
                y_next=$y_curr
            fi
            echo -n "$(get_body_char $x_prev $y_prev $x_curr $y_curr $x_next $y_next)"
        fi
    done
    tput cup 0 0
    echo "Score: $score"
}

# Update snake and food display (optimized to reduce flicker)
update_display() {
    local ate_food=$1
    # Clear tail if snake didn't eat food
    if [[ $ate_food -eq 0 ]]; then
        tput cup $tail_y $tail_x; echo -n " "
        # Redraw segment before tail to fix corner character
        if ((${#snake_x[@]} > 1)); then
            local idx=$(( ${#snake_x[@]} - 1 ))
            local x_prev=${snake_x[$((idx-1))]}
            local y_prev=${snake_y[$((idx-1))]}
            local x_curr=${snake_x[$idx]}
            local y_curr=${snake_y[$idx]}
            tput cup $y_curr $x_curr
            echo -n "$(get_body_char $x_prev $y_prev $x_curr $y_curr $x_curr $y_curr)"
        fi
    fi
    # Draw new head
    tput cup ${snake_y[0]} ${snake_x[0]}; echo -n "$SNAKE_HEAD"
    # Draw new body segment (previous head becomes body)
    if ((${#snake_x[@]} > 1)); then
        local x_prev=${snake_x[0]}
        local y_prev=${snake_y[0]}
        local x_curr=${snake_x[1]}
        local y_curr=${snake_y[1]}
        local x_next=${snake_x[2]:-$x_curr}  # Use current if no next segment
        local y_next=${snake_y[2]:-$y_curr}
        tput cup $y_curr $x_curr
        echo -n "$(get_body_char $x_prev $y_prev $x_curr $y_curr $x_next $y_next)"
    fi
    # Draw food
    tput cup $food_y $food_x; echo -n "$FOOD"
    # Update score
    tput cup 0 0; echo "Score: $score"
}

# Spawn food
spawn_food() {
    while :; do
        food_x=$((RANDOM % WIDTH + 1))
        food_y=$((RANDOM % HEIGHT + 1))
        for ((i=0; i<${#snake_x[@]}; i++)); do
            if [[ ${snake_x[$i]} -eq $food_x && ${snake_y[$i]} -eq $food_y ]]; then
                continue 2
            fi
        done
        break
    done
}

# Read input
read_input() {
    read -rsn1 -t $DELAY key
    key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
    case "$key" in
        w) [[ $dir != "down" ]] && dir="up" ;;
        s) [[ $dir != "up" ]] && dir="down" ;;
        a) [[ $dir != "right" ]] && dir="left" ;;
        d) [[ $dir != "left" ]] && dir="right" ;;
        *) ;;
    esac
}

# Update snake position
update_snake() {
    head_x=${snake_x[0]}
    head_y=${snake_y[0]}
    tail_x=${snake_x[-1]}  # Store tail position
    tail_y=${snake_y[-1]}

    case "$dir" in
        up)    ((head_y--)) ;;
        down)  ((head_y++)) ;;
        left)  ((head_x--)) ;;
        right) ((head_x++)) ;;
    esac

    # Check collisions
    if (( head_x < 1 || head_x > WIDTH || head_y < 1 || head_y > HEIGHT )); then
        game_over
    fi

    for ((i=1; i<${#snake_x[@]}; i++)); do
        if [[ ${snake_x[$i]} -eq $head_x && ${snake_y[$i]} -eq $head_y ]]; then
            game_over
        fi
    done

    # Move snake
    snake_x=($head_x "${snake_x[@]}")
    snake_y=($head_y "${snake_y[@]}")

    # Eat food
    ate_food=0
    if [[ $head_x -eq $food_x && $head_y -eq $food_y ]]; then
        ((score++))
        spawn_food
        ate_food=1
    else
        unset 'snake_x[-1]'
        unset 'snake_y[-1]'
    fi

    update_display $ate_food
}

# End game
game_over() {
    tput cup $((HEIGHT+3)) 0
    echo "Game Over! Your score: $score"
    echo "Controls: WASD              Ctrl+C to quit"
    stty echo
    tput cnorm
    exit
}

# Setup
stty -echo
tput civis
draw_border
spawn_food
draw_snake

# Game loop
while :; do
    read_input
    update_snake
done
