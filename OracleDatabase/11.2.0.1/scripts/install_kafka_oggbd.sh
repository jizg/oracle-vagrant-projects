export JAVA_VERSION='1.8.0'
export SCALA_VERSION='2.12'
export KAFKA_VERSION='2.8.1'
export ORACLE_GG_BD_SETUP_FILE='*BigData_*.zip'
echo 'INSTALLER: Started up'

# get up to date
yum upgrade -y

echo 'INSTALLER: System updated'

# fix locale warning
yum reinstall -y glibc-common
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'


# Create Directories
mkdir -p /u01/oggbd
mkdir -p /vagrant/oggbd
mkdir -p /usr/local/kafka

chown oracle:oinstall -R /u01/oggbd


# Install Java 8
echo 'INSTALLER: Install Java 8'
yum install -y java-$JAVA_VERSION-openjdk

# Install Apache Kafka
KAFKA_SCALA_VERSION="$SCALA_VERSION-$KAFKA_VERSION"
echo "Downloading Apache Kafka Version $KAFKA_VERSION"
curl "https://downloads.apache.org/kafka/$KAFKA_VERSION/kafka_$KAFKA_SCALA_VERSION.tgz" -# -o /tmp/kafka_$KAFKA_SCALA_VERSION.tgz

echo "Extracting Kafka to /usr/local/kafka/kafka_$KAFKA_SCALA_VERSION"
sudo tar -xzf /tmp/kafka_$KAFKA_SCALA_VERSION.tgz -C /usr/local/kafka/
rm /tmp/kafka_$KAFKA_SCALA_VERSION.tgz

sudo sed -i -e 's|^#advertised\.listeners=*.*$|advertised.listeners=PLAINTEXT://'$MACHINE_IP':9092|g' /usr/local/kafka/kafka_$KAFKA_SCALA_VERSION/config/server.properties
sudo cp /vagrant/scripts/services/zookeeper.service /etc/systemd/system/
sudo cp /vagrant/scripts/services/kafka.service /etc/systemd/system/

su -l oracle -c "echo 'export PATH=\$PATH:/usr/local/kafka/kafka_'$KAFKA_SCALA_VERSION'/bin/:' >> /home/oracle/.bashrc"

echo 'Creating Zookeeper and Kafka System Services'

sudo sed -i -e "s|###KAFKA_VERSION###|$KAFKA_SCALA_VERSION|g" /etc/systemd/system/zookeeper.service

sudo sed -i -e "s|###JAVA_VERSION###|$JAVA_VERSION|g" /etc/systemd/system/kafka.service
sudo sed -i -e "s|###KAFKA_VERSION###|$KAFKA_SCALA_VERSION|g" /etc/systemd/system/kafka.service

sudo systemctl daemon-reload
sudo systemctl enable zookeeper
sudo systemctl enable kafka

sudo systemctl start zookeeper
sudo systemctl start kafka

echo 'INSTALLER: Apache Kafka Installed and Started'

# Install Golden Gate For Big Data
echo 'Installer: Install GG for Big Data'
unzip /vagrant/$ORACLE_GG_BD_SETUP_FILE -d /tmp/oggbd
sudo tar -xvf /tmp/oggbd/*BigData_*.tar -C /u01/oggbd/
rm -rf /tmp/oggbd
chown -R oracle:oinstall /u01/oggbd/
echo 'INSTALLER: Oracle GG For Big Data Installed.'
