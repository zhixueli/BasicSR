echo "===Installation Started==="

# Chech subtring util function
has_substring() {
        string="$1"
        substring="$2"
        # ${string#*$substring} - strip $string of the smallest prefix of pattern `*$substring`
        # Stripping should also work, i.e. ${string%"$substring"*}
        # Copied from https://tiny.amazon.com/rj6h3xs1/stacques2829howd
        # Works for POSIX shell
        if test "${string#*$substring}" != "$string"; then
                return 0 # $substring is in $string
        else
                return 1 # $substring is not in $string
        fi
}

# Check OS version
is_debian_10() {
        . /etc/os-release
        if has_substring "$NAME" "Debian" && [ "$VERSION_ID" = "10" ]; then
                return 0
        else
                return 1
        fi
}

is_debian_11() {
        . /etc/os-release
        if has_substring "$NAME" "Debian" && [ "$VERSION_ID" = "11" ]; then
                return 0
        else
                return 1
        fi
}

echo "===Checking OS==="

if is_debian_10; then
        VERSION_CODENAME="bionic"
        echo "This is Debian $VERSION_ID. Mapping to Ubuntu $VERSION_CODENAME."
elif is_debian_11; then
        VERSION_CODENAME="focal"
        echo "This is Debian $VERSION_ID. Mapping to Ubuntu $VERSION_CODENAME."
fi

echo "===Configure Neuron repository==="
sudo apt-get update -y

# Configure Linux for Neuron repository updates
sudo tee /etc/apt/sources.list.d/neuron.list > /dev/null <<EOF
deb https://apt.repos.neuron.amazonaws.com ${VERSION_CODENAME} main
EOF
sudo apt-get install wget gnupg -y
wget -qO - https://apt.repos.neuron.amazonaws.com/GPG-PUB-KEY-AMAZON-AWS-NEURON.PUB | sudo apt-key add -

# Update OS packages
sudo apt-get update -y

# Install OS headers
sudo apt-get install linux-headers-$(uname -r) -y

# Install git
sudo apt-get install git -y

echo "===Install Neuron Driver, Runtime and Tools==="

# Install Neuron Driver
sudo apt-get install aws-neuronx-dkms=2.* -y

# Install Neuron Runtime
sudo apt-get install aws-neuronx-collectives=2.* -y
sudo apt-get install aws-neuronx-runtime-lib=2.* -y

# Install Neuron Tools
sudo apt-get install aws-neuronx-tools=2.* -y

# Add PATH
export PATH=/opt/aws/neuron/bin:$PATH

# Install EFA Driver (only required for multi-instance training)
echo "===Install EFA==="

wget https://efa-installer.amazonaws.com/aws-efa-installer-latest.tar.gz
wget https://efa-installer.amazonaws.com/aws-efa-installer.key && gpg --import aws-efa-installer.key
cat aws-efa-installer.key | gpg --fingerprint
wget https://efa-installer.amazonaws.com/aws-efa-installer-latest.tar.gz.sig && gpg --verify ./aws-efa-installer-latest.tar.gz.sig
tar -xvf aws-efa-installer-latest.tar.gz
cd aws-efa-installer && sudo bash efa_installer.sh --yes
cd
sudo rm -rf aws-efa-installer-latest.tar.gz aws-efa-installer


echo "===Install PyTorch Neuron==="
# Install Python venv
sudo apt-get install -y python3-venv g++

# Create Python venv
python3 -m venv aws_neuron_venv_pytorch

# Activate Python venv
. aws_neuron_venv_pytorch/bin/activate
python -m pip install -U pip

# Install Jupyter notebook kernel
pip install ipykernel
python3 -m ipykernel install --user --name aws_neuron_venv_pytorch --display-name "Python (torch-neuronx)"
pip install jupyter notebook
pip install environment_kernels

# Set pip repository pointing to the Neuron repository
python -m pip config set global.extra-index-url https://pip.repos.neuron.amazonaws.com

# Install awscli
python -m pip install awscli

# Install Neuron Compiler and Framework
python -m pip install neuronx-cc==2.* torch-neuronx torchvision

# List Packages
echo "===List Neuron Packages==="
pip list | grep neuron
apt list --installed | grep neuron

echo "===List EFA Packages==="
cat /opt/amazon/efa_installed_packages

echo "===Installation Completed==="