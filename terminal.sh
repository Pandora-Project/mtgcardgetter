#!/bin/bash

# Default output directory
output_dir="./downloads"

# Function to display help message
show_help() {
    echo "Usage: $0 [-h] [-o output_directory] [-i] [-v] [-n name] [-k oracle_keywords] [-t card_type] [-c color] [-m mana_value] [-s set]"
    echo ""
    echo "Options:"
    echo "  -h                Show this help message and exit"
    echo "  -o output_dir     Specify the output directory for downloads"
    echo "  -i                Run in interactive mode"
    echo "  -v                Run in visual mode"
    echo "  -n name           Specify the card name"
    echo "  -k oracle_keywords Specify the oracle keywords"
    echo "  -t card_type      Specify the card type"
    echo "  -c color          Specify the card color"
    echo "  -m mana_value     Specify the mana value"
    echo "  -s set            Specify the card set"
}

# Initialize variables
name=""
oracle_keywords=""
card_type=""
color=""
mana_value=""
set=""
interactive_mode=false
visual_mode=false

# Load data from data.json
data=$(jq '.' data.json)
set_list=$(echo "$data" | jq -r '.setList')
keywords=$(echo "$data" | jq -r '.keywords')
color_list=$(echo "$data" | jq -r '.colors')
types=$(echo "$data" | jq -r '.types')

# Parse command-line options
while getopts "ho:in:k:t:c:m:s:v" opt; do
    case ${opt} in
        h)
            show_help
            exit 0
            ;;
        o)
            output_dir="$OPTARG"
            ;;
        i)
            interactive_mode=true
            ;;
        v) 
            visual_mode=true
            ;;
        n) 
            name="$OPTARG" 
            ;;
        k) 
            oracle_keywords="$OPTARG" 
            ;;
        t) 
            card_type="$OPTARG" 
            ;;
        c) 
            color="$OPTARG" 
            ;;
        m) 
            mana_value="$OPTARG"
            ;;
        s) 
            set="$OPTARG" 
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
done

# Ensure the output directory exists
mkdir -p "$output_dir"

if [ "$interactive_mode" = true ]; then
    # Loop until user submits the form
    while true; do
        clear
        echo "1. Name"
        echo "2. Mana value"
        echo "3. Card type"
        echo "4. Oracle keywords"
        echo "5. Set"
        echo "6. Color"
        echo "7. Submit"
        echo "8. Exit"

        read -p "Enter your choice: " choice
        case $choice in
            1)
                clear
                # Validate user input for name
                while true; do
                    read -p "Input name: " name
                    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
                    if [[ "$name" =~ ^[a-zA-Z\ ]*$ ]]; then
                        break
                    else
                        echo "Invalid name. Please enter letters and spaces only."
                    fi
                done
                ;;
            2)
                clear
                # Validate user input for mana value
                while true; do
                    read -p "Input mana value (0-16): " mana_value
                    if [[ "$mana_value" =~ ^[0-9]{1,2}$ ]] && [ "$mana_value" -ge 0 ] && [ "$mana_value" -le 16 ]; then
                        break
                    else
                        echo "Invalid mana value. Please enter a valid mana value."
                    fi
                done
                ;;
            3)
                clear
                #Validate user input for card type
                lower_types=$(echo "$types" | tr '[:upper:]' '[:lower:]')
                echo "$lower_types"
                while true; do
                    read -p "Input card type: " card_type
                    card_type=$(echo "$card_type" | tr '[:upper:]' '[:lower:]')
                    if echo "$lower_types" | grep -iwq "\b$card_type\b"; then
                        break
                    else
                        echo "Invalid card type. Please enter a valid card type."
                    fi
                done
                ;;
            4)
                clear
                # Validate user input for oracle keywords
                lower_keywords=$(echo "$keywords" | tr '[:upper:]' '[:lower:]')
                while true; do
                    read -p "Input oracle keywords: " oracle_keywords
                    oracle_keywords=$(echo "$oracle_keywords" | tr '[:upper:]' '[:lower:]')
                    if echo "$lower_keywords" | grep -iq "$oracle_keywords"; then
                        break
                    else
                        echo "Invalid oracle keyword. Please enter a valid oracle keyword."
                    fi
                done
                ;;
            5)
                clear
                # Validate user input for set code
                while true; do
                    read -p "Input set code (3 letters): " set_code
                    set_code=$(echo $set_code | tr '[:upper:]' '[:lower:]')
                    if [[ ${#set_code} -eq 3 ]] && echo "$set_list" | grep -iq "\b$set_code\b"; then
                        break
                    else
                        echo "Invalid set code. Please enter a valid 3-letter set code."
                    fi
                done
                ;;
            6)
                clear
                # Validate user input for color
                lower_colors=$(echo "$color_list" | tr '[:upper:]' '[:lower:]')
                echo "$lower_colors"
                while true; do
                    read -p "Input color: " color
                    color=$(echo $color | tr '[:upper:]' '[:lower:]')
                    if echo "$lower_colors" | grep -iwq "\b$color\b"; then
                        break
                    else
                        echo "Invalid color. Please enter a valid color."
                    fi
                done
                ;;
            7)
                clear
                echo "Submitting..."
                query=""
                [ -n "$name" ] && query="${query}${name}"
                [ -n "$oracle_keywords" ] && query="${query}+oracle%3A${oracle_keywords}"
                [ -n "$card_type" ] && query="${query}+type%3A${card_type}"
                [ -n "$color" ] && query="${query}+color%3A${color}"
                [ -n "$mana_value" ] && query="${query}+cmc%3D${mana_value}"
                query="${query}+%28game%3Apaper%29"
                
                # Define the output directory for text response
                text_output_dir="${output_dir}/text_responses"
                mkdir -p "$text_output_dir"

                # Save the txt response to a file in the specified directory
                timestamp=$(date +"%Y%m%d_%H%M%S")
                output_file="${text_output_dir}/response_${timestamp}.txt"
                mkdir -p "$(dirname "$output_file")"
                perl main.pl "$query" "$output_file" $visual_mode
                echo "Text response saved to $output_file"

                # Ask user if they want to save the images
                read -p "Do you want to save the images as well? (y/n): " save_images
                if [[ "$save_images" =~ ^[Yy]$ ]]; then
                    image_output_dir="${output_dir}/images"
                    mkdir -p "$image_output_dir"
                    mv /tmp/card_*.jpg "$image_output_dir"
                    echo "Images saved to $image_output_dir"
                else
                    echo "User declined to save images. Deleting temporary images."
                    rm -f /tmp/card_*.jpg
                fi
                break
                ;;
            8)
                clear
                echo "Exiting..."
                exit 0
                ;;
            *)
                clear
                echo "Invalid choice. Please choose a number between 1 and 7."
                ;;
        esac
    done
else
    # Non-interactive mode
    query=""
    [ -n "$name" ] && query="${query}${name}"
    [ -n "$oracle_keywords" ] && query="${query}+oracle%3A${oracle_keywords}"
    [ -n "$card_type" ] && query="${query}+type%3A${card_type}"
    [ -n "$color" ] && query="${query}+color%3A${color}"
    [ -n "$mana_value" ] && query="${query}+cmc%3D${mana_value}"
    [ -n "$set" ] && query="${query}+set%3A${set}"
    query="${query}+%28game%3Apaper%29"

    # Define the output directory for text response
    text_output_dir="${output_dir}/text_responses"
    mkdir -p "$text_output_dir"

    # Save the txt response to a file in the specified directory
    timestamp=$(date +"%Y%m%d_%H%M%S")
    output_file="${text_output_dir}/response_${timestamp}.txt"
    mkdir -p "$(dirname "$output_file")"
    perl main.pl "$query" "$output_file" $visual_mode
    echo "Text response saved to $output_file"

    # Ask user if they want to save the images
    read -p "Do you want to save the images as well? (y/n): " save_images
    if [[ "$save_images" =~ ^[Yy]$ ]]; then
        image_output_dir="${output_dir}/images"
        mkdir -p "$image_output_dir"
        mv /tmp/card_*.jpg "$image_output_dir"
        echo "Images saved to $image_output_dir"
    else
        echo "User declined to save images. Deleting temporary images."
        rm -f /tmp/card_*.jpg
    fi
fi