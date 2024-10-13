#!/bin/bash

#!/bin/bash

# Display RADAR tool banner
echo "=================================="
echo "     ____  ____   ____   ____      "
echo "    |  _ \\|  _ \\ / ___| / ___|    "
echo "    | |_) | |_) | |  _  \\___ \\    "
echo "    |  __/|  _ <| |_| |  ___) |   "
echo "    |_|   |_| \\_\\\\____| |____/    "
echo "=================================="
echo "            RADAR Tool            "
echo "   Subdomain and Nmap Scanner     "
echo "=================================="
echo ""

# Function to display help
usage() {
    echo "Usage: $0 -t <domains_file> -o <output_file>"
    echo "  -t : File containing the list of domains"
    echo "  -o : Name of the output report file"
    exit 1
}

# Function to check and install Sublist3r
check_and_install_sublist3r() {
    if [ ! -d "Sublist3r" ]; then
        echo "Sublist3r is not installed. Downloading..."
        git clone https://github.com/aboul3la/Sublist3r.git
        if [ $? -ne 0 ]; then
            echo "Error downloading Sublist3r. Please check your internet connection and git installation."
            exit 1
        fi
        echo "Sublist3r downloaded successfully."
    else
        echo "Sublist3r is already present."
    fi
}

# Function to perform Nmap scan
nmap_scan() {
    local target=$1
    local output_file=$2
    echo "Ongoing scan on target: $target" >&2
    nmap -sC -sV $target -oN $output_file > /dev/null 2>&1
    echo "Scan on target: $target is finished" >&2
}
# Parsing command line arguments
while getopts ":t:o:" opt; do
    case ${opt} in
        t ) input_file=$OPTARG ;;
        o ) output_file=$OPTARG ;;
        \? ) usage ;;
        : ) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

# Check if required options are provided
if [[ -z $input_file ]] || [[ -z $output_file ]]; then
    usage
fi

# Check if input file exists
if [[ ! -f $input_file ]]; then
    echo "Input file $input_file does not exist."
    exit 1
fi

# Check if nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "Nmap is not installed. Please install Nmap and try again."
    exit 1
fi

# Check and install Sublist3r
check_and_install_sublist3r

# Create or overwrite the output file
> "$output_file"

# Process each domain
while IFS= read -r domain; do
    echo "Subdomain enumeration of : $domain" >&2
    # Run Sublist3r and save results temporarily
    python Sublist3r/sublist3r.py -d "$domain" -o subdomains_temp.txt > /dev/null 2>&1
    # Ask the user if they want to scan all subdomains of the domain
    echo "Do you want to scan all subdomains for the domain '$domain'? (y/n): " >&2
    read scan_all < /dev/tty
    # Add formatted results to the output file
    {
        echo "--------------------"
        echo "$domain"
        echo "--------------------"
        while IFS= read -r subdomain; do
            if [[ "$scan_all" == "y" || "$scan_all" == "Y" ]]; then
                # Scan all subdomains without asking
                echo "* $subdomain"
                echo "   * Scan $subdomain"
                nmap_scan $subdomain nmap_temp.txt
                sed 's/^/     /' nmap_temp.txt >> "$output_file"
                rm nmap_temp.txt
            else
                # Ask the user for each subdomain
                echo "Do you want to scan the subdomain '$subdomain'? (y/n): ">&2 
                read scan_subdomain < /dev/tty
                if [[ "$scan_subdomain" == "y" || "$scan_subdomain" == "Y" ]]; then
                    echo "* $subdomain"
                    echo "   * Scan $subdomain"
                    nmap_scan $subdomain nmap_temp.txt
                    sed 's/^/     /' nmap_temp.txt >> "$output_file"
                    rm nmap_temp.txt
                else
                    echo "* $subdomain (skipped)"
                fi
            fi
        done < subdomains_temp.txt
        echo ""  # Empty line to separate domains
    } >> "$output_file"

    # Clean up temporary file
    rm subdomains_temp.txt
done < "$input_file"

echo "Enumeration and scanning completed. Report saved in $output_file" >&2
