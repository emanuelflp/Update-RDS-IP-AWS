#!/bin/bash

# Script para update automatico do IP do RDS no /etc/hosts a cada 1 minuto.

USER=`whoami`
if [ $USER != "root" ]; then
    echo "Este processo deve ser executado como root."
    exit 1;
fi
criaarquivords(){
    while true; do
        read -p "Digite a URL que deseja atualizar: " HOSTNAMEFILE
        if [ "$HOSTNAMEFILE" != "" ]; then
             echo "$HOSTNAMEFILE=" > /etc/hosts.rds;
             break;
        fi
    done
}
if [ ! -f /etc/hosts.rds ]; then
while true; do
    read -p "Arquivo /etc/hosts.rds não encontrado. Deseja cria-lo? (Y,n): " yn
    case $yn in
           "" ) criaarquivords;break;;
        [Yy]* ) criaarquivords;break;;
        [Nn]* ) exit 1;;
    esac
done
fi

inserecron() {
    PWD=`pwd`
    while true; do
        read -p "Digite o nome deste script (update-ip.sh):" nomearquivo
        if [ "$nomearquivo" = "" ];then
             nomearquivo=update-ip.sh
        fi
        if [ -e $PWD/$nomearquivo ]; then
             cp $PWD/$nomearquivo /opt/update-ip.sh;
             break;
        else
             echo "Arquivo $PWD/$nomearquivo não encontrado."
        fi
    done
    crontab -l | { cat; echo "* * * * * sh /opt/update-ip.sh"; } | crontab -
}

VERIFICACRON=`crontab -l | grep -q "/opt/update-ip.sh";echo $?`
if [ $VERIFICACRON -ne 0 ]; then
     while true; do
         read -p "Deseja incluir este Script no Cron? (Y,n): " ifyn
         case $ifyn in
                "") inserecron;break;;
            [Yy]* ) inserecron;break;;
            [Nn]* ) break;;
         esac
     done
fi

HOST=`awk -F '[=]' '{print $1}' /etc/hosts.rds`
if [ "$HOST" = "" ]; then

    exit 1;
fi
IPFILE=`awk -F '[=]' '{print $2}' /etc/hosts.rds`
DNSMASQFILE=`cat /etc/resolv.conf |grep "nameserver" | awk '{print $2}'`
NEWIP=`dig @$DNSMASQFILE $HOST +noall +answer |tail -n1|awk -F " " '{print $NF }'`
if [ "$NEWIP" = "" ]; then
    exit 1;
fi
if [ "$IPFILE" != "$NEWIP" ]; then

    VERIFICAFILEHOST=`grep -q $HOST /etc/hosts ; echo $?`
    if [ $VERIFICAFILEHOST -eq 0 ]; then
        sed -i "/$HOST/d" /etc/hosts

    fi
    sed -i '/^$/d' /etc/hosts
    sed -i '/./!d' /etc/hosts
    echo "$NEWIP $HOST" >> /etc/hosts
    sed -i "/$HOST/d" /etc/hosts.rds
    echo "$HOST=$NEWIP" >> /etc/hosts.rds
    echo "O novo IP é $NEWIP"
fi
