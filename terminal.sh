# Default output directory
output_dir="./downloads"

# Function to display help message
show_help() {
    echo "Usage: $0 [-h] [-o output_directory]"
    echo ""
    echo "Options:"
    echo "  -h                Show this help message and exit"
    echo "  -o output_dir     Specify the output directory for downloads"
}

# Parse command-line options
while getopts "ho:" opt; do
    case ${opt} in
        h)
            show_help
            exit 0
            ;;
        o)
            output_dir="$OPTARG"
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
done

# Ensure the output directory exists
mkdir -p "$output_dir"

# Load types, keywords, colors, and set list from files
if [ -f types.txt ]; then
    types=$(cat types.txt)
else
    echo "Error: types.txt not found."
    exit 1
fi

if [ -f keywords.txt ]; then
    keywords=$(cat keywords.txt)
else
    echo "Error: keywords.txt not found."
    exit 1
fi

if [ -f colors.txt ]; then
    color_list=$(cat colors.txt)
else
    echo "Error: colors.txt not found."
    exit 1
fi

if [ -f SetList.json ]; then
    set_list=$(jq -r 'keys[]' SetList.json)
    if [ -z "$set_list" ]; then
        echo "Error: 'sets' key not found or empty in SetList.json."
        exit 1
    fi
else
    echo "Error: SetList.json not found."
    exit 1
fi

# Initialize variables
name=""
mana_value=""
card_type=""
set_code=""
oracle_keywords=""
color=""
api_string=""

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
            query="${query}+%28game%3Apaper%29"
            [ -n "$mana_value" ] && query="${query}+cmc%3D${mana_value}"
            
            # Save the txt response to a file in the current directory's downloads folder
            timestamp=$(date +"%Y%m%d_%H%M%S")
            output_file="${output_dir}/($timestamp)response.json"
            mkdir -p "$(dirname "$output_file")"
            perl main.pl "$query" > "$output_file"
            echo "Text response saved to $output_file"

            # Ask user if they want to download the images
            read -p "Do you want to download the pictures as well? (y/n): " download_pics
            if [[ "$download_pics" =~ ^[Yy]$ ]]; then
                mkdir -p "${output_dir}/images"
                while IFS= read -r line; do
                    if [[ $line == Image:* ]]; then
                        url=$(echo $line | cut -d' ' -f2-)
                        filename=$(basename "$url" | cut -d'?' -f1)  # Extract the filename and remove query parameters
                        wget -O "${output_dir}/images/$filename" "$url"
                        sleep 0.05  # 50 milliseconds delay
                    fi
                done < "$output_file"
                echo "Images downloaded to ${output_dir}/images"
            fi

            break
            ;;
        *)
            clear
            echo "Invalid choice. Please choose a number between 1 and 7."
            ;;
    esac
done
