vc_initialize_ruby_exec () {
    local embedded_dir
    local ruby_exec
    local src

    src=$(which vagrant)
    if [ $? -eq 0 ]; then
        embedded_dir="$(vc_get_file_dir "${src}")/../embedded"

        unset RUBYOPT
        ruby_exec="${embedded_dir}/bin/ruby"
    else
        ruby_exec=$(which ruby)
        if [ ! $? -eq 0 ]; then
            vc_printerr "$0: Cannot find Ruby (needed to serve kickstart file)"
            exit 4
        fi
    fi

    printf "${ruby_exec}"
}

vc_initialize_setup_box () {
    VBoxManage createvm --name ${NAME} --ostype ${TYPE} --register

    VBoxManage modifyvm ${NAME} \
        --vram 12 \
        --accelerate3d off \
        --memory 613 \
        --usb off \
        --audio none \
        --boot1 disk --boot2 dvd --boot3 none --boot4 none \
        --nictype1 virtio --nic1 nat --natnet1 "${NATNET}" \
        --nictype2 virtio \
        --nictype3 virtio \
        --nictype4 virtio \
        --acpi on --ioapic off \
        --chipset piix3 \
        --rtcuseutc on \
        --hpet on \
        --bioslogofadein off \
        --bioslogofadeout off \
        --bioslogodisplaytime 0 \
        --biosbootmenu disabled

    VBoxManage createhd --filename "${HDD}" --size 8192
    VBoxManage createhd --filename "${HDD_SWAP}" --size 1226

    VBoxManage storagectl ${NAME} \
        --name SATA --add sata --portcount 2 --bootable on

    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 0 --type hdd --medium "${HDD}"
    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 1 --type hdd --medium "${HDD_SWAP}"
    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 2 --type dvddrive --medium "${INSTALLER}"
    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 3 --type dvddrive --medium "${GUESTADDITIONS}"

    VBoxManage startvm ${NAME} --type gui
}

vc_initialize_start_httpd () {
    # This only really caters for the common case. If you have
    # problems, please discover your host's IP address and adjust
    # accordingly.
    IP=${NATNET%.*/*}

    printf "At the boot prompt, hit <TAB> and then type:\n\n"
    printf " ks=http://${IP}.3:"

    ruby=$(vc_initialize_ruby_exec)
    "${ruby}" "${ROOT_DIR}/src/httpd.rb" \
        "$1"
}

vc_initialize_cleanup_msg () {
    printf "\n\n"
    printf "The box has accepted the kickstart file. It will now go through\n"
    printf "a lengthy install. When it is finished it will shutdown and you\n"
    printf "can run:\n\n"
    printf "    ./box cleanup && vagrant package --base ${NAME} --output boxes/${NAME}-`date +%Y%m%d`.box\n\n"
    printf "to create a Vagrant box.\n"
}

vc_action_initialize () {
    local ruby

    vc_initialize_setup_box
    if [ -z "${C_KICKSTART}" ]; then
        vc_initialize_start_httpd "${ROOT_DIR}/etc/ks/centos65-x86_64.cfg"
    else
        vc_initialize_start_httpd "${C_KICKSTART}"
    fi

    vc_initialize_cleanup_msg
}
