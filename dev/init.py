#!/usr/bin/env python3
# ./dev/init.py
# usage: python ./dev/init.py
import os
import subprocess


def create_conda_env(env_name):
    print(f"Creating Conda environment '{env_name}'...")
    subprocess.run(["conda", "create", "-n", env_name, "python=3.8", "-y"])
    print(f"Conda environment '{env_name}' created.")


def activate_conda_env(env_name):
    print(f"Activating Conda environment '{env_name}'...")
    if os.name == "posix":
        subprocess.run(["conda", "activate", env_name], shell=True)
    elif os.name == "nt":
        subprocess.run(["activate", env_name], shell=True)
    else:
        raise Exception("Unsupported OS.")
    print(f"Conda environment '{env_name}' activated.")


def install_molecule(env_name):
    print("Installing Molecule and its dependencies...")
    subprocess.run(
        [
            "conda",
            "install",
            "-n",
            env_name,
            "-c",
            "conda-forge",
            "molecule",
            "molecule-docker",
            "-y",
        ]
    )
    print("Molecule and its dependencies installed.")


def main():
    env_name = "molecule_env"
    create_conda_env(env_name)
    activate_conda_env(env_name)
    install_molecule(env_name)


if __name__ == "__main__":
    main()
