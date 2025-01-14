#!/bin/bash
# This script can be run on the AWS Deep Learning AMI, to set up the machine for
# use with tensorflow-wavenet.
#
# Although it is often wise to install Python dependencies with virtual
# environments, I’m going to disregard it since this is for a temporary
# on-demand instance.
#
# To avoid PATH problems with sudo and PIP,
# and HOME problems with sudo and --generate-config,
# call this script using
#
#     sudo env PATH=$PATH env HOME=$HOME ./setup.sh
#
# Update the system
sudo apt-get update
# Install tmux
echo "Installing tmux"
sudo apt-get install tmux
# Install Jupyter
echo "Installing Jupyter"
# Path problem with sudo, see:
# http://stackoverflow.com/questions/257616/sudo-changes-path-why
sudo env PATH=$PATH `which pip` install jupyter
# The --generate-config argument generates a config in the
# HOME directory.
jupyter notebook --generate-config
key=$(python -c "from notebook.auth import passwd; print(passwd())")
mkdir /home/ubuntu/certs
cd /home/ubuntu/certs
certdir=$(pwd)
openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout mycert.key -out mycert.pem
cd /home/ubuntu
sed -i "1 a\
c = get_config()\\
c.NotebookApp.certfile = u'$certdir/mycert.pem'\\
c.NotebookApp.ip = '*'\\
c.NotebookApp.open_browser = False\\
c.NotebookApp.password = u'$key'\\
c.NotebookApp.port = 8888" .jupyter/jupyter_notebook_config.py
mkdir /home/ubuntu/notebooks
sudo chown -R ubuntu:ubuntu /home/ubuntu/notebooks
# Update Tensorflow
echo "Updating TensorFlow"
cd /home/ubuntu/src/tensorflow
git pull
# Fix Amazon Linux TensorFlow bug
MATPLOTLIBRC=`python -c "import matplotlib; print(matplotlib.matplotlib_fname())"`
sudo sed -i 's/tkagg/agg/' $MATPLOTLIBRC
# Install tensorflow-wavenet
echo "Installing tensorflow-wavenet"
cd /home/ubuntu/src
git clone https://github.com/ibab/tensorflow-wavenet.git
cd tensorflow-wavenet
sudo env PATH=$PATH `which pip` install -r requirements_gpu.txt
sudo chown -R ubuntu:ubuntu .
# Install ffprobe/ffmpeg for youtube-dl
# http://ftrack.rtd.ftrack.com/en/3.3.9/administering/managing_local_installation/configuring_ffmpeg.html
# https://www.johnvansickle.com/ffmpeg/

echo "Installing ffprobe"
cd /opt
sudo wget https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-64bit-static.tar.xz
sudo tar -xf ffmpeg-git-64bit-static.tar.xz
sudo rm ffmpeg-git-64bit-static.tar.xz
sudo ln -s /opt/ffmpeg*/ff* /usr/bin
echo "Installing youtube-dl"
sudo wget https://yt-dl.org/latest/youtube-dl -O /usr/local/bin/youtube-dl
sudo chmod a+x /usr/local/bin/youtube-dl
hash -r

echo "Updating dask"
sudo env PATH=$PATH `which pip`  install dask --upgrade

echo "Getting dataset of 4 hours of classical piano music"
mkdir -p ~/data/wavenet_corpus
cd ~/data/wavenet_corpus
youtube-dl --extract-audio --audio-format wav https://www.youtube.com/watch?v=EhO_MrRfftU

echo "Exporting Library Path"
cd ~/src/tensorflow-wavenet
export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64
