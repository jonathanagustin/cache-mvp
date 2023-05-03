#!/usr/bin/env bash
# ./scripts/bash.sh

# This script installs Podman and runs a Redis container on various Linux distributions.
# Must run with sudo privileges.

# Check if the script is running with sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges."
    exit 1
fi

# Detect the Linux distribution
distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')

# Print help message
print_help() {
    echo "Usage: sudo ./bash.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --fake-data    Load fake data into the Redis database"
    echo "  --help         Show this help message and exit"
}

# Install Podman based on the detected distribution
install_podman() {
    echo "Installing Podman for $distro..."

    case $distro in
    "Arch Linux" | "Manjaro Linux")
        pacman -S --noconfirm podman
        ;;
    "Alpine Linux")
        apk add podman
        ;;
    "CentOS Linux")
        yum -y install podman
        ;;
    "Debian GNU/Linux")
        apt-get -y install podman
        ;;
    "Fedora")
        dnf -y install podman
        ;;
    "Gentoo")
        emerge app-containers/podman
        ;;
    "openSUSE Leap" | "openSUSE Tumbleweed")
        zypper install -y podman
        ;;
    "Red Hat Enterprise Linux")
        local version_id
        version_id=$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release | tr -d '"')
        if [ "$version_id" -eq 7 ]; then
            subscription-manager repos --enable=rhel-7-server-extras-rpms
            yum -y install podman
        else
            yum module enable -y container-tools:rhel8
            yum module install -y container-tools:rhel8
        fi
        ;;
    "Ubuntu")
        apt-get -y update
        apt-get -y install podman
        ;;
    *)
        echo "Unsupported Linux distribution."
        exit 1
        ;;
    esac

    echo "Podman installation completed."
}

# Run a Redis container using Podman
run_redis_container() {
    echo "Pulling Redis image..."
    podman pull redis:latest

    echo "Running Redis container..."
    podman run --name redis -d -p 6379:6379 redis:latest

    echo "Redis container is running."
}

# Load fake_data.json into the Redis database
fake_data() {
    if [ ! -f "../roles/redis/files/fake_data.json" ]; then
        echo "fake_data.json file not found."
        exit 1
    fi

    echo "Loading fake_data.json into Redis database..."
    podman exec -i redis redis-cli -x set fake_data <../roles/redis/files/fake_data.json
    echo "fake_data.json loaded into Redis database."
}

# Main script execution
while [ "$#" -gt 0 ]; do
    case "$1" in
    --fake-data)
        fake_data_flag=true
        shift
        ;;
    --help)
        print_help
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        print_help
        exit 1
        ;;
    esac
done

install_podman
run_redis_container

if [ "$fake_data_flag" = true ]; then
    fake_data
fi
