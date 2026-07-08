#!/bin/sh

handle_recommended_profile() {

    while IFS= read -r pkg
    do
        [ -z "$pkg" ] && continue

        add_package "$pkg"

    done <<EOF
luci-app-passwall2
xray-core
sing-box
geoview
v2ray-geoip
v2ray-geosite
EOF

}