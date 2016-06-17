#!/bin/bash
set -e

CONDA_INSTALL_PATH="/usr/local/bin/miniconda"

# 0. Specify Miniconda version
# 0.1 A few parameters
# specify base operating system
OS_TYPE="Linux-x86_64.sh"

## Python 2 or 3?
MINICONDA_VARIANT="Miniconda3"  #for Python 3.5.x
expectedHash="b1b15a3436bb7de1da3ccc6e08c7a5df"
# specify Miniconda release
MINICONDA_VER='4.0.5'

## 0. Compute Miniconda version
miniconda="$MINICONDA_VARIANT-$MINICONDA_VER-$OS_TYPE"

# 1. Setup Miniconda Install
## 1.1 Define Miniconda install directory
echo "Working directory: $PWD"
if [ $# -eq 0 ]
    then
    echo "No path argument specified, setting install directory as working directory: $PWD."
    PROJ_DIR=$PWD

else
    echo "Path argument specified, installing to: $1"
    PROJ_DIR=$1
fi

## 1.2 Setup Miniconda
cd $PROJ_DIR
MINICONDA_SCRIPT_PATH="$PROJ_DIR/$miniconda"
echo "Defined miniconda script path: $MINICONDA_SCRIPT_PATH"

if [[ -f "$MINICONDA_SCRIPT_PATH" ]]; then
  echo "Found existing Miniconda script at: $MINICONDA_SCRIPT_PATH"
else
  echo "Downloading Miniconda script to: $MINICONDA_SCRIPT_PATH ..."
  wget http://repo.continuum.io/miniconda/$miniconda -P "$PROJ_DIR"
  echo "Downloaded $miniconda!"
  ls -al $MINICONDA_SCRIPT_PATH
  chmod 755 $MINICONDA_SCRIPT_PATH
fi

# 1.3 #md5sum hash check of miniconda installer
md5Output=$(md5sum $MINICONDA_SCRIPT_PATH | awk '{print $1}')
if [ "$expectedHash" != "$md5Output" ]; then
    echo "Unexpected md5sum $md5Output for $miniconda"
    exit 1
fi

# 2. Install Conda
## 2.1 Via bootstrap
LOCAL_CONDA_PATH="$PROJ_DIR/miniconda"
if [[ ! -d $LOCAL_CONDA_PATH ]]; then
    #blow away old symlink / default Miniconda install
    rm -rf "$PROJ_DIR/miniconda"
    # Install Miniconda
    echo "Installing $miniconda to $CONDA_INSTALL_PATH..."
    bash $MINICONDA_SCRIPT_PATH -b -p $CONDA_INSTALL_PATH -f
    chmod 755 $CONDA_INSTALL_PATH
    #create symlink
    ln -sf $CONDA_INSTALL_PATH "$PROJ_DIR/miniconda"
    chmod 755 "$PROJ_DIR/miniconda"
else
    echo "Existing directory at path: $LOCAL_CONDA_PATH, skipping install!"
fi

# 2.2 Update PATH and conda...
echo "Setting environment variables..."
CONDA_BIN_PATH="$CONDA_INSTALL_PATH/bin"
export PATH="$CONDA_BIN_PATH:$PATH"
echo "Updated PATH: $PATH"
echo "And also HOME: $HOME"
hash -r
which conda
conda config --set always_yes true --set changeps1 false
source ~/.bashrc

echo "Updating conda..."
conda update -q conda
# Useful for debugging any issues with conda
    conda info -a

# Install useful conda utilities in root env
echo "Installing useful conda utilities in root env..."
conda install anaconda-client conda-build

# 2.3 Update global profiles to add the miniconda location to PATH
echo "Updating global profiles to export miniconda bin location to PATH..."
if grep -ir "CONDA_BIN_PATH=$CONDA_BIN_PATH" /etc/profile  #/$HOME/.bashrc
    then
    echo "CONDA_BIN_PATH found in /etc/profile , skipping..."
else
    echo "Adding path definition to profiles..."
    echo "export CONDA_BIN_PATH=$CONDA_BIN_PATH" | tee -a /etc/profile.d/conda_config.sh /etc/*bashrc /etc/profile #/etc/environment
    #echo "export CONDA_BIN_PATH=$CONDA_BIN_PATH" | tee -a $HOME/*shrc
    echo 'export PATH=$CONDA_BIN_PATH:$PATH' | tee -a /etc/profile.d/conda_config.sh  /etc/*bashrc /etc/profile #/etc/environment

fi

echo "Finished bootstrapping via Miniconda, sourcing /etc/profile ..."
source /etc/profile
