#!/usr/bin/env bash

work_path=/opt/apps/com.qianxin.trustagent/files/bin
lib_path=/opt/apps/com.qianxin.trustagent/files/lib
app_path=/opt/apps/com.qianxin.trustagent

get_user() {
    USER_NAME=$(getent passwd $(who) | head -n 1 | cut -d : -f 1)

    if [ -z "$USER_NAME" ]; then
        USER_NAME=$(who | awk '{print $1}' | head -1)
    fi

    if [ -z "$USER_NAME" ]; then
        USER_NAME=root
    fi
}

config_app() {
    chmod 666 $work_path/TrustAgent.config
    chmod 666 $work_path/TrustAgentExtra.config
    chmod 444 $work_path/TrustAgentSetting.config

    # ST-28335 Set all file rw-r--r-- keep x
    chmod -R u=rwX,g=rX,o=rX $app_path/
    chmod +x $app_path/files/bin/TrustAgent
    chmod +x $app_path/files/bin/trustdns
    chmod +x $app_path/files/bin/trustdservice
    chmod +x $app_path/files/bin/trustservice
    chmod +x $app_path/files/bin/trustservicemgr
    chmod +x $app_path/files/bin/trustvnic
}

init_log() {
    if [ ! -f "/var/log/trustcore.log" ]; then
        touch "/var/log/trustcore.log"
    fi
    if [ ! -d /var/log/TrustAgent/ ]; then
        mkdir /var/log/TrustAgent/
    fi
    chmod 777 /var/log/TrustAgent/
    chmod -R a=rwX /var/log/TrustAgent/
    chmod 777 /var/log/trustcore.log
}

config_qt() {
    if [ -f $lib_path/build_qt_ln.sh ]; then
        /bin/sh -x $lib_path/build_qt_ln.sh
    fi
    get_user
    if [ ! -d /home/$USER_NAME/.TrustAgent ]; then
        sudo -u $USER_NAME mkdir /home/$USER_NAME/.TrustAgent
    fi
    sudo -u $USER_NAME /bin/cp -rf $work_path/TrustAgentExtra.config /home/$USER_NAME/.TrustAgent/TrustAgentExtra.config
}

remove_trust_certificate() {
    for user_home in /home/*; do
        while IFS= read -r db_file; do
            db_dir=$(dirname "$db_file")
            # 尝试查找已存在的证书
            certutil_output=$(LD_LIBRARY_PATH=$work_path"/cert/":$lib_path $work_path/certutil -d sql:"$db_dir" -L | grep "trust@localhost")
            #        LD_LIBRARY_PATH=$lib_path $work_path/certutil -d sql:"$db_dir" -D -n "trust@localhost"
            if [ -n "$certutil_output" ]; then
                # 删除证书
                LD_LIBRARY_PATH=$work_path"/cert/":$lib_path $work_path/certutil -d sql:"$db_dir" -D -n "trust@localhost"
                if [ $? -eq 0 ]; then
                    echo "'trust@localhost' removed successfully from $db_dir."
                else
                    echo "Failed to remove 'trust@localhost' from $db_dir."
                fi
            fi
        done < <(find $user_home/.pki/ $user_home/.mozilla/ -name "cert9.db")
    done
}

install_certificate_to_nss() {
    for user_home in /home/*; do
        while IFS= read -r db_file; do
            db_dir=$(dirname "$db_file")
            echo "Checking $db_dir"
            # 尝试查找已存在的证书
            certutil_output=$(LD_LIBRARY_PATH=$work_path"/cert/":$lib_path $work_path/certutil -d sql:"$db_dir" -L | grep "trust@localhost")
            if [ -z "$certutil_output" ]; then
                echo "No 'trust@localhost' found in $db."
                LD_LIBRARY_PATH=$work_path"/cert/":$lib_path $work_path/certutil -d sql:"$db_dir" -A -t "C,," -n "trust@localhost" -i "/usr/share/ca-certificates/ztna_server.pem"
                if [ $? -eq 0 ]; then
                    echo "'trust@localhost' added successfully to $db_dir."
                else
                    echo "Failed to add 'trust@localhost' to $db_dir."
                fi
            else
                echo "'trust@localhost' already exists in $db_dir."
            fi
        done < <(find $user_home/.pki/ $user_home/.mozilla/ -name "cert9.db")
    done
}

install_certificate() {
    cp $work_path/rootCA.pem /usr/share/ca-certificates/ztna_server.pem
    # 检查 /etc/ca-certificates.conf 是否存在
    if [ -f /etc/ca-certificates.conf ]; then
        grep -q "ztna_server.pem" /etc/ca-certificates.conf
        if [ $? -ne 0 ]; then
            echo "ztna_server.pem" >>/etc/ca-certificates.conf
        fi
    else
        echo "ztna_server.pem" >>/etc/ca-certificates.conf
    fi
    update-ca-certificates --fresh
    remove_trust_certificate
    install_certificate_to_nss
}

save_spa() {
    # 临时存储deb的安装包名称作为spa的秘钥，程序启动后会读取然后删除此文件
    pkgoutput=$(ps aux | grep dpkg)
    #packagename=$($work_path/trustservice --spakey "$pkgoutput")
    #or use shell to match package filename
    #[[ ${pkgoutput} =~ (TrustAgent_?.+(\.deb)) ]]
    #allpackagename=${BASH_REMATCH[1]}
    #packagename=""
    #for i in $(echo $allpackagename | tr " " "\n")
    #do
    #    if [[ ${i} == *"TrustAgent"* ]]; then
    #        packagename=${i}
    #    fi
    #done
    packagename=$(echo "$pkgoutput" | grep -o 'TrustAgent_[^[:blank:]]*.deb')

    # _ -> @
    packagename=$(echo "$packagename" | rev | sed -e 's/\]\([^@_]*\)_\([^@_]*\)\(.*\)\[/]\1@\2\3[/g' | sed -e 's/\]\([^_]*_*\)\([^@_]*\)[@_]\(.*\)\[/]\1\2@\3[/g' | rev)

    if [ ! -d /var/log/TrustAgent/ ]; then
        mkdir -p /var/log/TrustAgent/
    fi

    if [ -n "$packagename" ]; then
        echo $packagename >/var/log/TrustAgent/spatemp.file
        echo $packagename >/var/log/TrustAgent/package.txt
    fi

    #工行项目要求packagename不能包含ip，因此检测安装路径是否存在spafile，如果安装包内置了进行覆盖，默认使用安装包中的spa信息
    if [ -e "$work_path/spatemp.file" ]; then
        /bin/cp -rf "$work_path/spatemp.file" /var/log/TrustAgent/spatemp.file
    fi
    if [ -e "$work_path/package.txt" ]; then
        /bin/cp -rf "$work_path/package.txt" /var/log/TrustAgent/package.txt
    fi

    if [ ! -f /var/log/TrustAgent/install.txt ]; then
        echo "install_type=user" >/var/log/TrustAgent/install.txt
    fi

    chmod 777 /var/log/TrustAgent/
}

deploy_service() {
    if [ ! -d /usr/share/trustagent ]; then
        mkdir -p /usr/share/trustagent
    fi
    chmod 777 /usr/share/trustagent

    systemctl enable trustdservice.service
    systemctl enable trustfrontservice.service
    systemctl enable trustservicemgr.service
    systemctl enable trustnet.service
}

init_log
save_spa
config_app
install_certificate
config_qt
deploy_service

exit 0
